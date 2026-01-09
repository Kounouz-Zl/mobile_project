import os
from app import create_app

# Get environment (development or production)
env = os.getenv('FLASK_ENV', 'development')

# Create Flask app
app = create_app(env)

if __name__ == '__main__':  # Fixed this line
    # Get port from environment or default to 5000
    port = int(os.getenv('PORT', 5000))
    
    # Run the Flask development server
    app.run(
        host='0.0.0.0',  # Listen on all network interfaces
        port=port,        # Port number
        debug=(env == 'development')  # Enable debug mode in development
    )