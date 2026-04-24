import os
from supabase import create_client, Client, ClientOptions
from dotenv import load_dotenv

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")

# Increase timeout to 30 seconds to prevent ReadTimeout issues
options = ClientOptions(
    postgrest_client_timeout=30,
    storage_client_timeout=30,
    schema="public"
)

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY, options=options)
