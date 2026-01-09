from supabase import create_client, Client
from flask import current_app
import logging

logger = logging.getLogger(__name__)

class SupabaseClient:
    _instance = None
    _client: Client = None
    _anon_client: Client = None
    _url: str = None
    _anon_key: str = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(SupabaseClient, cls).__new__(cls)
        return cls._instance
    
    def init_app(self, app):
        """Initialize Supabase client with Flask app config"""
        self._url = app.config['SUPABASE_URL']
        # Use ANON_KEY for client-side auth operations, fallback to SUPABASE_KEY if not set
        self._anon_key = app.config.get('SUPABASE_ANON_KEY') or app.config.get('SUPABASE_KEY')
        service_key = app.config.get('SUPABASE_KEY')
        
        # Create client with anon key for client-side auth
        self._anon_client = create_client(
            self._url,
            self._anon_key
        )
        
        # Create client with service key for admin operations (if different)
        if service_key and service_key != self._anon_key:
            self._client = create_client(
                self._url,
                service_key
            )
        else:
            self._client = self._anon_client
    
    @property
    def client(self) -> Client:
        """Get Supabase client instance (for admin operations)"""
        if self._client is None:
            raise Exception("Supabase client not initialized. Call init_app() first.")
        return self._client
    
    @property
    def anon_client(self) -> Client:
        """Get Supabase client instance with anon key (for client-side auth operations)"""
        if self._anon_client is None:
            raise Exception("Supabase client not initialized. Call init_app() first.")
        return self._anon_client
    
    def get_user_from_token(self, token: str):
        """
        Get user from JWT token by validating with Supabase.
        Creates a temporary client instance to avoid session conflicts.
        """
        if not token:
            logger.error("Token is empty")
            return None
            
        try:
            # Create a new client instance with anon key for token validation
            # This ensures we don't interfere with the main client's session
            temp_client = create_client(
                self._url,
                self._anon_key
            )
            
            # Validate token by calling get_user with the JWT token
            # This will verify the token signature and expiration
            user_response = temp_client.auth.get_user(token)
            
            if user_response and user_response.user:
                return user_response
            else:
                logger.error("get_user returned None or no user")
                return None
                    
        except Exception as e:
            # Log the actual error for debugging
            error_msg = str(e)
            logger.error(f"Token validation failed: {error_msg}")
            # Return None instead of raising - let decorator handle the error message
            return None

# Singleton instance
supabase_client = SupabaseClient()