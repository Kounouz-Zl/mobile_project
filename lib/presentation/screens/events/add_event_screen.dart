import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '/../logic/cubits/user/user_cubit.dart';
import '/../logic/cubits/user/user_state.dart';
import '/../logic/cubits/language/language_cubit.dart';
import '../../l10n/app_localizations.dart';
import '/data/models/event.dart';
import '/../data/databases/database_helper.dart';

class AddEventScreen extends StatefulWidget {
  final Event? eventToEdit;

  const AddEventScreen({Key? key, this.eventToEdit}) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _locationAddressController = TextEditingController();
  final _organizerNameController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  String? _eventImagePath;
  String? _organizerImagePath;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCategory;
  int _attendeesCount = 0;
  bool _isLoading = false;

  final List<String> categories = [
    'Business',
    'Community',
    'Music & Entertainment',
    'Health',
    'Food & drink',
    'Family & Education',
    'Sport',
    'Fashion',
    'Film & Media',
    'Home & Lifestyle',
    'Design',
    'Gaming',
    'Science & Tech',
    'School & Education',
    'Holiday',
    'Travel',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _populateFields(widget.eventToEdit!);
    }
  }

  void _populateFields(Event event) {
    _titleController.text = event.title;
    _descriptionController.text = event.description;
    _locationController.text = event.location;
    _locationAddressController.text = event.locationAddress;
    _organizerNameController.text = event.organizerName;
    _eventImagePath = event.imageUrl;
    _organizerImagePath = event.organizerImageUrl;
    _attendeesCount = event.attendeesCount;
    _selectedCategory = event.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _locationAddressController.dispose();
    _organizerNameController.dispose();
    super.dispose();
  }

  Future<void> _pickEventImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
      );
      
      if (image != null) {
        setState(() {
          _eventImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error_picking_image')}: $e')),
      );
    }
  }

  Future<void> _pickOrganizerImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (image != null) {
        setState(() {
          _organizerImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${context.tr('error_picking_image')}: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_date'))),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_category'))),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userState = context.read<UserCubit>().state;
      String? userId;
      if (userState is UserLoaded) {
        userId = userState.user.id;
      }

      // Format the date and time
      String formattedDate = DateFormat('dd MMM, yyyy').format(_selectedDate!);
      if (_selectedTime != null) {
        formattedDate += ' ${_selectedTime!.format(context)}';
      }

      final event = Event(
        id: widget.eventToEdit?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        locationAddress: _locationAddressController.text.trim(),
        date: formattedDate,
        imageUrl: _eventImagePath ?? 'https://via.placeholder.com/400x200',
        organizerName: _organizerNameController.text.trim(),
        organizerImageUrl: _organizerImagePath ?? 'https://via.placeholder.com/100',
        attendeesCount: _attendeesCount,
        category: _selectedCategory,
        createdBy: userId,
      );

      final db = DatabaseHelper.instance;
      
      if (widget.eventToEdit != null) {
        await db.updateEvent(event);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('event_updated_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await db.insertEvent(event, userId: userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('event_created_successfully')),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (context, locale) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5F3FF),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.eventToEdit != null ? context.tr('edit_event') : context.tr('create_new_event'),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Image Picker
                        _buildSectionTitle(context.tr('event_image_required')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickEventImage,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _eventImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(_eventImagePath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 60,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('tap_to_add_event_image'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Event Title
                        _buildSectionTitle(context.tr('event_title_required')),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _titleController,
                          hint: context.tr('enter_event_title'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_enter_event_title');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Category Dropdown
                        _buildSectionTitle(context.tr('category_required')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              hint: Text(context.tr('select_category')),
                              items: categories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Event Description
                        _buildSectionTitle(context.tr('description_required')),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _descriptionController,
                          hint: context.tr('enter_event_description'),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_enter_description');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Location
                        _buildSectionTitle(context.tr('location_name_required')),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _locationController,
                          hint: context.tr('location_hint'),
                          prefixIcon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_enter_location');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Location Address
                        _buildSectionTitle(context.tr('location_address_required')),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _locationAddressController,
                          hint: context.tr('location_address_hint'),
                          prefixIcon: Icons.map,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_enter_address');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Date and Time
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('event_date_required')),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectDate,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              color: Colors.grey, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedDate == null
                                                ? context.tr('select')
                                                : DateFormat('dd/MM/yy')
                                                    .format(_selectedDate!),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _selectedDate == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(context.tr('time')),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: _selectTime,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              color: Colors.grey, size: 20),
                                          const SizedBox(width: 12),
                                          Text(
                                            _selectedTime == null
                                                ? context.tr('select')
                                                : _selectedTime!.format(context),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _selectedTime == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Organizer Name
                        _buildSectionTitle(context.tr('organizer_name_required')),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _organizerNameController,
                          hint: context.tr('organizer_name_hint'),
                          prefixIcon: Icons.person,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return context.tr('please_enter_organizer_name');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Organizer Image
                        _buildSectionTitle(context.tr('organizer_image')),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickOrganizerImage,
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _organizerImagePath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(_organizerImagePath!),
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.account_circle,
                                        size: 40,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('tap_to_add_organizer_image'),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Attendees Count
                        _buildSectionTitle(context.tr('expected_attendees')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, color: Colors.grey),
                              const SizedBox(width: 12),
                              Text(
                                context.tr('people_count').replaceAll('{count}', '$_attendeesCount'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  if (_attendeesCount > 0) {
                                    setState(() {
                                      _attendeesCount--;
                                    });
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    _attendeesCount++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              widget.eventToEdit != null
                                  ? context.tr('update_event')
                                  : context.tr('create_event'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}