
from flask import Blueprint, request, jsonify
from app.utils.supabase_client import supabase_client
from app.utils.decorators import token_required, organizer_required
from app.utils.email_utils import send_email
from datetime import datetime
import uuid
from werkzeug.utils import secure_filename

# Create blueprint for event routes
events_bp = Blueprint('events', __name__, url_prefix='/api/events')

# ========== GET ALL EVENTS ==========
@events_bp.route('/', methods=['GET'])
def get_all_events():
    """
    Get all events (public, no auth required).
    
    Response:
    {
        "events": [...]
    }
    """
    try:
        supabase = supabase_client.client
        result = supabase.table('events').select('*').order('created_at', desc=True).execute()
        return jsonify({'events': result.data}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET SINGLE EVENT ==========
@events_bp.route('/<event_id>', methods=['GET'])
def get_event(event_id):
    """
    Get single event by ID.
    
    URL: /api/events/123-456-789
    """
    try:
        supabase = supabase_client.client
        result = supabase.table('events').select('*').eq('id', event_id).execute()
        
        if not result.data:
            return jsonify({'error': 'Event not found'}), 404
        
        return jsonify({'event': result.data[0]}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== UPLOAD IMAGE ==========
@events_bp.route('/upload-image', methods=['POST'])
@token_required
def upload_image(current_user):
    """Upload an image to Supabase storage events bucket"""
    try:
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Validate file type
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
        filename = secure_filename(file.filename)
        file_ext = filename.rsplit('.', 1)[1].lower() if '.' in filename else ''
        
        if file_ext not in allowed_extensions:
            return jsonify({'error': f'Invalid file type. Allowed: {", ".join(allowed_extensions)}'}), 400
        
        # Generate unique filename
        unique_filename = f"{uuid.uuid4()}.{file_ext}"
        file_path = f"{current_user.user.id}/{unique_filename}"
        
        supabase = supabase_client.client
        
        # Read file content
        file_content = file.read()
        
        # Determine content type
        content_type = f'image/{file_ext}' if file_ext != 'jpg' else 'image/jpeg'
        
        # Upload to Supabase storage
        try:
            # Upload to events bucket
            response = supabase.storage.from_('events').upload(
                file_path,
                file_content,
                file_options={'content-type': content_type, 'upsert': 'false'}
            )
            
            # Get public URL
            public_url = supabase.storage.from_('events').get_public_url(file_path)
            
            return jsonify({
                'message': 'Image uploaded successfully',
                'url': public_url,
                'path': file_path
            }), 200
            
        except Exception as storage_error:
            # If bucket doesn't exist or upload fails, return error
            print(f'Storage upload error: {storage_error}')
            return jsonify({'error': f'Failed to upload image: {str(storage_error)}'}), 500
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== CREATE EVENT ==========
@events_bp.route('/', methods=['POST'])
@token_required
def create_event(current_user):
    """
    Create a new event.
    Requires authentication.
    
    Request Body:
    {
        "title": "...",
        "description": "...",
        "location": "...",
        "location_address": "...",
        "date": "...",
        "image_url": "...",
        "category": "..."  // optional
    }
    """
    try:
        data = request.get_json()
        
        # Validate required fields (removed organizer fields)
        required_fields = ['title', 'description', 'location', 'location_address', 
                   'date', 'image_url', 'category']

        
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        supabase = supabase_client.client
        
        # Get organization profile and user info
        org_profile = supabase.table('organization_profiles').select('*').eq('user_id', current_user.user.id).execute()
        user_info = supabase.table('users').select('username, profile_photo_url').eq('id', current_user.user.id).execute()
        
        organizer_name = user_info.data[0]['username'] if user_info.data else 'Unknown'
        organizer_image_url = user_info.data[0].get('profile_photo_url') if user_info.data else None
        
        # If organization profile exists, use profile name
        if org_profile.data:
            organizer_name = org_profile.data[0].get('name', organizer_name)
        
        # Prepare event data
        event_data = {
            'title': data['title'],
            'description': data['description'],
            'location': data['location'],
            'location_address': data['location_address'],
            'date': data['date'],
            'image_url': data['image_url'],
            'organizer_name': organizer_name,
            'organizer_image_url': organizer_image_url or '',
            'attendees_count': 0,
            'category': data.get('category'),
            'created_by': current_user.user.id,  # Set creator
            'event_date_time': data['date']
        }
        
        # Insert into database
        result = supabase.table('events').insert(event_data).execute()
        
        # Notify followers about new event
        try:
            followers = supabase.table('organization_follows').select('follower_id').eq('organization_id', current_user.user.id).execute()
            
            if followers.data:
                from app.routes.notifications import create_notification
                event_title = data['title']
                
                for follower in followers.data:
                    create_notification(
                        supabase,
                        follower['follower_id'],
                        'new_event',
                        f'New event from {organizer_name}',
                        f'{organizer_name} has created a new event: "{event_title}"',
                        result.data[0]['id'] if result.data else None
                    )
                # Send email notifications to followers if possible
                try:
                    follower_ids = [f['follower_id'] for f in followers.data]
                    users_resp = supabase.table('users').select('id, email, username').in_('id', follower_ids).execute()
                    if users_resp.data:
                        for u in users_resp.data:
                            try:
                                if u.get('email'):
                                    email_body = f"""
Hello {u.get('username', 'there')},

{organizer_name} has just created a new event: "{event_title}".

Open the app to view details and register.

Best regards,
Event Team
"""
                                    send_email(u['email'], f'New event: {event_title}', email_body)
                            except Exception as mail_err:
                                print(f"Error sending email to follower {u.get('id')}: {mail_err}")
                except Exception as mail_outer_err:
                    print(f'Error preparing follower emails: {mail_outer_err}')
        except Exception as notif_error:
            print(f'Error sending notifications: {notif_error}')
            # Don't fail event creation if notifications fail
        
        return jsonify({
            'message': 'Event created successfully',
            'event': result.data[0]
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ========== UPDATE EVENT ==========
@events_bp.route('/<event_id>', methods=['PUT'])
@token_required
def update_event(current_user, event_id):
    """
    Update an event.
    Only event creator can update.
    """
    try:
        supabase = supabase_client.client
        
        # Check if event exists and user owns it
        event = supabase.table('events').select('*').eq('id', event_id).execute()
        
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        if event.data[0]['created_by'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized - not event owner'}), 403
        
        data = request.get_json()
        update_data = {}
        
        # Only update provided fields (removed organizer_name and organizer_image_url from updatable)
        updatable_fields = ['title', 'description', 'location', 'location_address',
                           'date', 'image_url', 'category']
        
        for field in updatable_fields:
            if field in data:
                update_data[field] = data[field]
        
        # Always update organizer info from organization profile
        org_profile = supabase.table('organization_profiles').select('*').eq('user_id', current_user.user.id).execute()
        user_info = supabase.table('users').select('username, profile_photo_url').eq('id', current_user.user.id).execute()
        
        organizer_name = user_info.data[0]['username'] if user_info.data else 'Unknown'
        organizer_image_url = user_info.data[0].get('profile_photo_url') if user_info.data else None
        
        # If organization profile exists, use profile name
        if org_profile.data:
            organizer_name = org_profile.data[0].get('name', organizer_name)
        
        update_data['organizer_name'] = organizer_name
        update_data['organizer_image_url'] = organizer_image_url or ''
        
        if 'date' in update_data:
            update_data['event_date_time'] = update_data['date']
        
        # Update in database
        result = supabase.table('events').update(update_data).eq('id', event_id).execute()
        
        return jsonify({
            'message': 'Event updated successfully',
            'event': result.data[0]
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== DELETE EVENT ==========
@events_bp.route('/<event_id>', methods=['DELETE'])
@token_required
def delete_event(current_user, event_id):
    """
    Delete an event.
    Only event creator can delete.
    """
    try:
        supabase = supabase_client.client
        
        # Check ownership
        event = supabase.table('events').select('*').eq('id', event_id).execute()
        
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        if event.data[0]['created_by'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Delete (cascade will handle participants, registrations, favorites)
        supabase.table('events').delete().eq('id', event_id).execute()
        
        return jsonify({'message': 'Event deleted successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== JOIN EVENT ==========
@events_bp.route('/<event_id>/join', methods=['POST'])
@token_required
def join_event(current_user, event_id):
    """
    Join an event as a participant.
    """
    try:
        supabase = supabase_client.client
        
        # Check if already joined
        existing = supabase.table('event_participants').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        if existing.data:
            return jsonify({'message': 'Already joined this event'}), 200
        
        # Add participant
        supabase.table('event_participants').insert({
            'event_id': event_id,
            'user_id': current_user.user.id
        }).execute()
        
        # Increment attendees count
        event = supabase.table('events').select('attendees_count').eq('id', event_id).execute()
        new_count = event.data[0]['attendees_count'] + 1
        supabase.table('events').update({'attendees_count': new_count}).eq('id', event_id).execute()
        
        return jsonify({'message': 'Joined event successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== LEAVE EVENT ==========
@events_bp.route('/<event_id>/leave', methods=['POST'])
@token_required
def leave_event(current_user, event_id):
    """Leave an event"""
    try:
        supabase = supabase_client.client
        
        # Delete participant record
        result = supabase.table('event_participants').delete().eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        if result.data:
            # Decrement count
            event = supabase.table('events').select('attendees_count').eq('id', event_id).execute()
            new_count = max(0, event.data[0]['attendees_count'] - 1)
            supabase.table('events').update({'attendees_count': new_count}).eq('id', event_id).execute()
        
        return jsonify({'message': 'Left event successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== CHECK IF JOINED ==========
@events_bp.route('/<event_id>/is-joined', methods=['GET'])
@token_required
def check_joined(current_user, event_id):
    """Check if current user has joined event"""
    try:
        supabase = supabase_client.client
        result = supabase.table('event_participants').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        return jsonify({'is_joined': len(result.data) > 0}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== REGISTER FOR EVENT ==========
@events_bp.route('/<event_id>/register', methods=['POST'])
@token_required
def register_for_event(current_user, event_id):
    """
    Register for event with reason. Creates a PENDING registration.
    
    Request Body:
    {
        "user_name": "John Doe",
        "reason": "I love this event..."
    }
    """
    try:
        data = request.get_json()
        reason = data.get('reason', '')
        user_name = data.get('user_name', '')
        
        if not reason or not user_name:
            return jsonify({'error': 'User name and reason are required'}), 400
        
        supabase = supabase_client.client
        
        # Check if already registered (any status)
        existing = supabase.table('event_registrations').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        if existing.data:
            existing_status = existing.data[0].get('status', 'pending')
            return jsonify({'error': f'Already registered with status: {existing_status}'}), 400
        
        # Get event details to notify organizer
        event = supabase.table('events').select('created_by, title').eq('id', event_id).execute()
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        organizer_id = event.data[0]['created_by']
        event_title = event.data[0]['title']
        
        # Add registration with PENDING status
        registration = supabase.table('event_registrations').insert({
            'event_id': event_id,
            'user_id': current_user.user.id,
            'user_name': user_name,
            'reason': reason,
            'status': 'pending'  # Start as pending
        }).execute()
        
        if not registration.data:
            return jsonify({'error': 'Failed to create registration'}), 500
        
        # Create notification for organizer about new registration
        from app.routes.notifications import create_notification
        
        create_notification(
            supabase,
            organizer_id,
            'new_registration',
            f'New registration for "{event_title}"',
            f'{user_name} has submitted a registration request for your event.',
            event_id
        )
        
        return jsonify({
            'message': 'Registration request submitted successfully. Waiting for organizer approval.',
            'registration': registration.data[0]
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== CANCEL REGISTRATION ==========
@events_bp.route('/<event_id>/registrations/cancel', methods=['POST'])
@token_required
def cancel_registration(current_user, event_id):
    """Cancel a pending registration"""
    try:
        supabase = supabase_client.client
        
        # Find the registration
        registration = supabase.table('event_registrations').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        if not registration.data:
            return jsonify({'error': 'Registration not found'}), 404
        
        reg = registration.data[0]
        
        # Only allow canceling if pending
        if reg.get('status') != 'pending':
            return jsonify({'error': 'Can only cancel pending registrations'}), 400
        
        # Delete the registration
        supabase.table('event_registrations').delete().eq('id', reg['id']).execute()
        
        return jsonify({'message': 'Registration cancelled successfully'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET REGISTRATION STATUS ==========
@events_bp.route('/<event_id>/registration-status', methods=['GET'])
@token_required
def get_registration_status(current_user, event_id):
    """Get current user's registration status for an event"""
    try:
        supabase = supabase_client.client
        
        registration = supabase.table('event_registrations').select('*').eq('event_id', event_id).eq('user_id', current_user.user.id).execute()
        
        if not registration.data:
            return jsonify({'status': None}), 200
        
        reg = registration.data[0]
        return jsonify({
            'status': reg.get('status', 'pending'),
            'registration_id': reg['id']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET REGISTRATIONS FOR EVENT ==========
@events_bp.route('/<event_id>/registrations', methods=['GET'])
@token_required
def get_registrations(current_user, event_id):
    """Get all registrations for an event (organizer only)"""
    try:
        supabase = supabase_client.client
        
        # Verify user is the event organizer
        event = supabase.table('events').select('created_by').eq('id', event_id).execute()
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        if event.data[0]['created_by'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized - You are not the event organizer'}), 403
        
        # Get all registrations - order by id instead of created_at (created_at column may not exist)
        registrations_result = supabase.table('event_registrations').select('*').eq('event_id', event_id).order('id', desc=True).execute()
        
        # Handle case where registrations.data might be None
        registrations_list = registrations_result.data if registrations_result.data else []
        
        return jsonify(registrations_list), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== APPROVE REGISTRATION ==========
@events_bp.route('/<event_id>/registrations/<registration_id>/approve', methods=['PUT'])
@token_required
def approve_registration(current_user, event_id, registration_id):
    """Approve a pending registration (organizer only)"""
    try:
        supabase = supabase_client.client
        
        # Verify user is the event organizer
        event = supabase.table('events').select('created_by, title').eq('id', event_id).execute()
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        if event.data[0]['created_by'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Get registration
        registration = supabase.table('event_registrations').select('*').eq('id', registration_id).eq('event_id', event_id).execute()
        if not registration.data:
            return jsonify({'error': 'Registration not found'}), 404
        
        reg = registration.data[0]
        participant_user_id = reg['user_id']
        
        # Update status to approved
        supabase.table('event_registrations').update({'status': 'approved'}).eq('id', registration_id).execute()
        
        # Add to event_participants if not already there
        existing = supabase.table('event_participants').select('*').eq('event_id', event_id).eq('user_id', participant_user_id).execute()
        if not existing.data:
            supabase.table('event_participants').insert({
                'event_id': event_id,
                'user_id': participant_user_id
            }).execute()
            
            # Increment attendees count
            event_data = supabase.table('events').select('attendees_count').eq('id', event_id).execute()
            new_count = event_data.data[0]['attendees_count'] + 1
            supabase.table('events').update({'attendees_count': new_count}).eq('id', event_id).execute()
        
        # Create notification for participant (import at function level to avoid circular imports)
        from app.routes.notifications import create_notification
        
        # Get participant email
        participant = supabase.table('users').select('email, username').eq('id', participant_user_id).execute()
        participant_email = participant.data[0]['email'] if participant.data else None
        
        event_title = event.data[0]['title']
        
        # Create in-app notification
        create_notification(
            supabase,
            participant_user_id,
            'approval',
            f'Your registration for "{event_title}" has been approved!',
            f'Congratulations! The organizer has approved your registration request.',
            event_id
        )
        
        # Send email notification
        if participant_email:
            try:
                email_body = f"""
Dear {reg.get('user_name', 'Participant')},

Great news! Your registration request for the event "{event_title}" has been approved by the organizer.

You are now registered to attend this event. We look forward to seeing you there!

Event Details:
- Event: {event_title}
- Date: Check event page for details

Best regards,
Event Team
"""
                send_email(participant_email, f'Registration Approved: {event_title}', email_body)
            except Exception as email_error:
                print(f'Error sending email: {email_error}')
        
        return jsonify({'message': 'Registration approved successfully'}), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== REJECT REGISTRATION ==========
@events_bp.route('/<event_id>/registrations/<registration_id>/reject', methods=['PUT'])
@token_required
def reject_registration(current_user, event_id, registration_id):
    """Reject a pending registration (organizer only)"""
    try:
        supabase = supabase_client.client
        
        # Verify user is the event organizer
        event = supabase.table('events').select('created_by, title').eq('id', event_id).execute()
        if not event.data:
            return jsonify({'error': 'Event not found'}), 404
        
        if event.data[0]['created_by'] != current_user.user.id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Get registration
        registration = supabase.table('event_registrations').select('*').eq('id', registration_id).eq('event_id', event_id).execute()
        if not registration.data:
            return jsonify({'error': 'Registration not found'}), 404
        
        reg = registration.data[0]
        participant_user_id = reg['user_id']
        
        # Update status to rejected
        supabase.table('event_registrations').update({'status': 'rejected'}).eq('id', registration_id).execute()
        
        # Remove from event_participants if there
        existing = supabase.table('event_participants').select('*').eq('event_id', event_id).eq('user_id', participant_user_id).execute()
        if existing.data:
            supabase.table('event_participants').delete().eq('event_id', event_id).eq('user_id', participant_user_id).execute()
            
            # Decrement attendees count
            event_data = supabase.table('events').select('attendees_count').eq('id', event_id).execute()
            new_count = max(0, event_data.data[0]['attendees_count'] - 1)
            supabase.table('events').update({'attendees_count': new_count}).eq('id', event_id).execute()
        
        # Create notification for participant (import at function level to avoid circular imports)
        from app.routes.notifications import create_notification
        
        # Get participant email
        participant = supabase.table('users').select('email, username').eq('id', participant_user_id).execute()
        participant_email = participant.data[0]['email'] if participant.data else None
        
        event_title = event.data[0]['title']
        
        # Create in-app notification
        create_notification(
            supabase,
            participant_user_id,
            'rejection',
            f'Registration update for "{event_title}"',
            f'Unfortunately, your registration request for "{event_title}" was not approved at this time.',
            event_id
        )
        
        # Send email notification
        if participant_email:
            try:
                email_body = f"""
Dear {reg.get('user_name', 'Participant')},

We regret to inform you that your registration request for the event "{event_title}" has not been approved at this time.

We appreciate your interest and encourage you to register for other events.

Best regards,
Event Team
"""
                send_email(participant_email, f'Registration Update: {event_title}', email_body)
            except Exception as email_error:
                print(f'Error sending email: {email_error}')
        
        return jsonify({'message': 'Registration rejected successfully'}), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

# ========== GET APPROVED COUNT ==========
@events_bp.route('/<event_id>/approved-count', methods=['GET'])
def get_approved_count(event_id):
    """Get count of approved registrations for an event"""
    try:
        supabase = supabase_client.client
        
        result = supabase.table('event_registrations').select('id', count='exact').eq('event_id', event_id).eq('status', 'approved').execute()
        
        count = result.count if hasattr(result, 'count') else len(result.data) if result.data else 0
        
        return jsonify({'count': count}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET POPULAR EVENTS ==========
@events_bp.route('/popular', methods=['GET'])
def get_popular_events():
    """
    Get popular events (sorted by attendees).
    Query param: ?limit=4
    """
    try:
        limit = request.args.get('limit', 4, type=int)
        supabase = supabase_client.client
        
        result = supabase.table('events').select('*').order('attendees_count', desc=True).limit(limit).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET UPCOMING EVENTS ==========
@events_bp.route('/upcoming', methods=['GET'])
def get_upcoming_events():
    """
    Get upcoming events.
    Query params: ?limit=4&categories=Music,Sports
    """
    try:
        limit = request.args.get('limit', 4, type=int)
        categories = request.args.getlist('categories')
        
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        query = supabase.table('events').select('*').gte('event_date_time', now)
        
        if categories:
            query = query.in_('category', categories)
        
        result = query.order('event_date_time').limit(limit).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET MY EVENTS ==========
@events_bp.route('/my-events', methods=['GET'])
@token_required
def get_my_events(current_user):
    """Get events created by current user"""
    try:
        supabase = supabase_client.client
        result = supabase.table('events').select('*').eq('created_by', current_user.user.id).order('created_at', desc=True).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET MY EVENTS UPCOMING ==========
@events_bp.route('/my-events/upcoming', methods=['GET'])
@token_required
def get_my_events_upcoming(current_user):
    """Get upcoming events joined by participant"""
    try:
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        # Get event IDs user has joined
        participants = supabase.table('event_participants').select('event_id').eq('user_id', current_user.user.id).execute()
        
        if not participants.data:
            return jsonify({'events': []}), 200
        
        event_ids = [p['event_id'] for p in participants.data]
        
        # Get upcoming events
        result = supabase.table('events').select('*').in_('id', event_ids).gte('event_date_time', now).order('event_date_time').execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET MY EVENTS PAST ==========
@events_bp.route('/my-events/past', methods=['GET'])
@token_required
def get_my_events_past(current_user):
    """Get past events joined by participant"""
    try:
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        # Get event IDs user has joined
        participants = supabase.table('event_participants').select('event_id').eq('user_id', current_user.user.id).execute()
        
        if not participants.data:
            return jsonify({'events': []}), 200
        
        event_ids = [p['event_id'] for p in participants.data]
        
        # Get past events
        result = supabase.table('events').select('*').in_('id', event_ids).lt('event_date_time', now).order('event_date_time', desc=True).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET ORGANIZED EVENTS UPCOMING ==========
@events_bp.route('/organized/upcoming', methods=['GET'])
@token_required
def get_organized_upcoming(current_user):
    """Get upcoming events created OR joined by current user (organization)"""
    try:
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        # Get events created by user
        created = supabase.table('events').select('*').eq('created_by', current_user.user.id).gte('event_date_time', now).execute()
        created_ids = [e['id'] for e in created.data] if created.data else []
        
        # Get events joined by user
        participants = supabase.table('event_participants').select('event_id').eq('user_id', current_user.user.id).execute()
        joined_ids = [p['event_id'] for p in participants.data] if participants.data else []
        
        # Combine and get unique event IDs
        all_event_ids = list(set(created_ids + joined_ids))
        
        if not all_event_ids:
            return jsonify({'events': []}), 200
        
        # Get all upcoming events
        result = supabase.table('events').select('*').in_('id', all_event_ids).gte('event_date_time', now).order('event_date_time').execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET ORGANIZED EVENTS PAST ==========
@events_bp.route('/organized/past', methods=['GET'])
@token_required
def get_organized_past(current_user):
    """Get past events created OR joined by current user (organization)"""
    try:
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        # Get events created by user
        created = supabase.table('events').select('*').eq('created_by', current_user.user.id).lt('event_date_time', now).execute()
        created_ids = [e['id'] for e in created.data] if created.data else []
        
        # Get events joined by user
        participants = supabase.table('event_participants').select('event_id').eq('user_id', current_user.user.id).execute()
        joined_ids = [p['event_id'] for p in participants.data] if participants.data else []
        
        # Combine and get unique event IDs
        all_event_ids = list(set(created_ids + joined_ids))
        
        if not all_event_ids:
            return jsonify({'events': []}), 200
        
        # Get all past events
        result = supabase.table('events').select('*').in_('id', all_event_ids).lt('event_date_time', now).order('event_date_time', desc=True).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET JOINED EVENTS ==========
@events_bp.route('/joined-events', methods=['GET'])
@token_required
def get_joined_events(current_user):
    """Get events user has joined"""
    try:
        supabase = supabase_client.client
        
        # Get event IDs user has joined
        participants = supabase.table('event_participants').select('event_id').eq('user_id', current_user.user.id).execute()
        
        if not participants.data:
            return jsonify({'events': []}), 200
        
        event_ids = [p['event_id'] for p in participants.data]
        
        # Get events
        result = supabase.table('events').select('*').in_('id', event_ids).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ========== GET RECOMMENDED EVENTS ==========
@events_bp.route('/recommended', methods=['GET'])
def get_recommended_events():
    """
    Get recommended events.
    Query param: ?limit=4
    For now, returns upcoming events sorted by attendees count.
    """
    try:
        limit = request.args.get('limit', 4, type=int)
        supabase = supabase_client.client
        now = datetime.now().isoformat()
        
        result = supabase.table('events').select('*').gte('event_date_time', now).order('attendees_count', desc=True).limit(limit).execute()
        
        return jsonify({'events': result.data}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500