from django.contrib import admin  # type: ignore
from .models import Property, PropertyImage

class PropertyImageInline(admin.TabularInline):
    model = PropertyImage
    extra = 1

@admin.register(Property)
class PropertyAdmin(admin.ModelAdmin):
    list_display = ('title', 'price', 'intent', 'status', 'created_at')
    list_filter = ('status', 'intent', 'requires_agent')
    search_fields = ('title', 'address', 'city')
    actions = ['approve_properties']
    inlines = [PropertyImageInline]

    @admin.action(description='Approve and unlock selected properties')
    def approve_properties(self, request, queryset):
        queryset.update(status='ACTIVE')
     