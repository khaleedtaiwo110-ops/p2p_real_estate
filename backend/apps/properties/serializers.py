from rest_framework import serializers  # type: ignore
from .models import Property, PropertyImage, PropertyReview

class PropertyImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = PropertyImage
        fields = ['id', 'image']

class PropertySerializer(serializers.ModelSerializer):
    images = PropertyImageSerializer(many=True, read_only=True)
    uploaded_images = serializers.ListField(
        child=serializers.ImageField(max_length=1000000, allow_empty_file=False, use_url=False),
        write_only=True,
        required=False
    )

    class Meta:
        model = Property
        fields = '__all__'
        read_only_fields = ['status'] # Status can only be changed by Admin/API trigger

    def create(self, validated_data):
        uploaded_images = validated_data.pop('uploaded_images', [])
        # Always force status to PENDING on creation
        validated_data['status'] = 'PENDING'
        
        property_obj = Property.objects.create(**validated_data)

        # Save photos attached in request
        for img in uploaded_images:
            PropertyImage.objects.create(property=property_obj, image=img)

        return property_obj

class PropertyReviewSerializer(serializers.ModelSerializer):
    user_name = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = PropertyReview
        fields = ['id', 'property', 'user_name', 'rating', 'comment', 'created_at']
        read_only_fields = ['user', 'property']    