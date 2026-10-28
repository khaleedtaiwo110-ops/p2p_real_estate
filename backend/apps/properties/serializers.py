import uuid
from rest_framework import serializers
from .models import Property, PropertyImage, PropertyReview

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
            return image_url
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
            PropertyImage.objects.create(property=property_obj, image=img)

        return property_obj


class PropertyReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = PropertyReview
        fields = ['id', 'property', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['user', 'property']   