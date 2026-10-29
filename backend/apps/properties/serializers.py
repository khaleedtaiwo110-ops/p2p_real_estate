import uuid
from rest_framework import serializers
from .models import Property, PropertyImage, PropertyReview
from .supabase_utils import upload_image_to_supabase

class PropertyImageSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = PropertyImage
        fields = ['id', 'image']

    def get_image(self, obj):
        if obj.image:
            # If the database already stores a full public URL, return it directly
            img_url_str = str(obj.image)
            if img_url_str.startswith('http://') or img_url_str.startswith('https://'):
                return img_url_str
            
            # Otherwise, build the absolute URI using the current request
            request = self.context.get('request')
            if request is not None:
                return request.build_absolute_uri(obj.image.url)
            
            # Fallback using your live Render backend domain
            return f"https://p2p-real-estate-backend.onrender.com{obj.image.url}"
        return None
    

class PropertySerializer(serializers.ModelSerializer):
    id = serializers.UUIDField(read_only=True)
    images = PropertyImageSerializer(many=True, read_only=True)
    uploaded_images = serializers.ListField(
        child=serializers.ImageField(max_length=1000000, allow_empty_file=False, use_url=False),
        write_only=True,
        required=False
    )

    class Meta:
        model = Property
        fields = '__all__'
        read_only_fields = ['id', 'status', 'created_at', 'updated_at']

    def create(self, validated_data):
        uploaded_images = validated_data.pop('uploaded_images', [])
        validated_data['status'] = 'PENDING'
        
        property_obj = Property.objects.create(**validated_data)

        for img in uploaded_images:
            try:
                # 1. Upload the image file to Supabase Storage and get its public URL
                supabase_url = upload_image_to_supabase(img)
                
                # 2. Save the public URL string into the PropertyImage record
                PropertyImage.objects.create(property=property_obj, image=supabase_url)
            except Exception as e:
                print(f"Failed to upload image to Supabase: {str(e)}")

        return property_obj


class PropertyReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = PropertyReview
        fields = ['id', 'property', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['user', 'property'] 