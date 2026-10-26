from rest_framework import serializers  # type: ignore
from .models import Property, PropertyImage, PropertyReview

class PropertyImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyImage
        fields = ['id', 'image']

class PropertyImageSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()

    class Meta:
        model = PropertyImage
        fields = ['id', 'image']

    def get_image(self, obj):
        if obj.image:
            request = self.context.get('request')
            image_url = obj.image.url
            if request is not None:
                return request.build_absolute_uri(image_url)
            return image_url  # Fallback if request context is missing
        return None

    
class PropertyReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = PropertyReview
        fields = ['id', 'property', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['user', 'property']    