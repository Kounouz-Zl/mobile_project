from flask import Flask
from flask_cors import CORS
from config import config
from app.utils.supabase_client import supabase_client

def create_app(config_name='development'):
    """
    Application factory function.
    Creates and configures the Flask app.
    """
    # Create Flask app instance
    app = Flask(__name__)
    
    # Load configuration from config.py
    app.config.from_object(config[config_name])
    
    # Enable CORS (Cross-Origin Resource Sharing)
    # This allows Flutter app to connect from different domain
    CORS(app, resources={
        r"/api/*": {
            "origins": "*",  # Allow all origins (change in production)
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
            "supports_credentials": True
        }
    })
    
    # Initialize Supabase client with app config
    supabase_client.init_app(app)
    
    # Import and register blueprints (routes)
    from app.routes.auth import auth_bp
    from app.routes.events import events_bp
    from app.routes.users import users_bp
    from app.routes.notifications import notifications_bp
    from app.routes.organizations import organizations_bp
    
    app.register_blueprint(auth_bp)          # /api/auth/*
    app.register_blueprint(events_bp)        # /api/events/*
    app.register_blueprint(users_bp)         # /api/users/*
    app.register_blueprint(notifications_bp) # /api/notifications/*
    app.register_blueprint(organizations_bp) # /api/organizations/*
    
    # Health check route
    @app.route('/health')
    def health():
        """Check if API is running"""
        return {'status': 'healthy', 'message': 'Events API is running'}, 200
    
    # Root route
    @app.route('/')
    def index():
        """API information"""
        return {
            'message': 'Events API',
            'version': '1.0.0',
            'endpoints': {
                'auth': '/api/auth',
                'events': '/api/events',
                'users': '/api/users'
            }
        }, 200
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        """Handle 404 errors"""
        return {'error': 'Resource not found'}, 404
    
    @app.errorhandler(500)
    def internal_error(error):
        """Handle 500 errors"""
        return {'error': 'Internal server error'}, 500
    
    @app.errorhandler(405)
    def method_not_allowed(error):
        """Handle 405 errors"""
        return {'error': 'Method not allowed'}, 405
    
    return app