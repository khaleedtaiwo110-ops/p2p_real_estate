import os
from supabase import create_client, Client

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

def upload_image_to_supabase(file_obj, path_prefix="property_photos"):
    if not SUPABASE_URL or not SUPABASE_KEY:
        raise Exception("Supabase credentials are missing in environment variables.")
    
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    
    file_name = f"{path_prefix}/{file_obj.name}"
    file_bytes = file_obj.read()
    
    # Upload file to Supabase 'property-images' bucket
    supabase.storage.from_("property-images").upload(
        path=file_name,
        file=file_bytes,
        file_options={"content-type": getattr(file_obj, 'content_type', 'image/jpeg'), "upsert": "true"}
    )
    
    # Get the public URL directly from Supabase Storage
    public_url_response = supabase.storage.from_("property-images").get_public_url(file_name)
    return public_url_response