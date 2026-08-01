import { LightningElement, track } from 'lwc';
import createProperty from '@salesforce/apex/PropertyController.createProperty';
import deleteProperty from '@salesforce/apex/PropertyController.deleteProperty';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PropertyCreate extends LightningElement {
    @track propertyId;
    @track uploadedFiles = [];

    // form field values
    address = '';
    city = '';
    state = '';
    postalCode = '';
    country = '';
    type = '';
    furnishingStatus = '';
    status = '';
    rent;
    description = '';

    typeOptions = [
        { label: 'Residential', value: 'Residential' },
        { label: 'Commercial', value: 'Commercial' }
    ];

    furnishingOptions = [
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    statusOptions = [
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    get acceptedFormats() {
        return ['.png', '.jpg', '.jpeg'];
    }

    // Step A: only enable file upload after required text fields are filled
    get isFormValid() {
        return this.address && this.city && this.state && this.postalCode &&
               this.country && this.type && this.status && this.rent && this.description;
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this[field] = event.target.value;
    }

    // Step B: create the record first (without it, file upload has nothing to attach to)
    async handleCreateAndPrepareUpload() {
        if (!this.isFormValid) {
            this.showToast('Error', 'Please fill all required fields first.', 'error');
            return;
        }
        try {
            this.propertyId = await createProperty({
                addressStr: this.address,
                cityStr: this.city,
                stateStr: this.state,
                postalCodeStr: this.postalCode,
                countryStr: this.country,
                typeStr: this.type,
                furnishingStr: this.furnishingStatus,
                statusStr: this.status,
                rentNum: this.rent,
                descriptionStr: this.description
            });
            this.showToast('Ready', 'Now attach at least one image to finish creating this property.', 'success');
        } catch (err) {
            this.showToast('Error', 'Could not create property: ' + err.body.message, 'error');
        }
    }

    handleUploadFinished(event) {
        this.uploadedFiles = event.detail.files;
        this.showToast('Success', 'Property created with image(s) successfully.', 'success');
        this.resetForm();
    }

    // Step C: if user navigates away without uploading, clean up the orphaned record
    async handleCancelWithoutImage() {
        if (this.propertyId && this.uploadedFiles.length === 0) {
            await deleteProperty({ propertyId: this.propertyId });
            this.showToast('Cancelled', 'Property was not saved because no image was attached.', 'warning');
        }
        this.resetForm();
    }

    resetForm() {
        this.propertyId = undefined;
        this.address = this.city = this.state = this.postalCode = this.country = '';
        this.type = this.furnishingStatus = this.status = this.description = '';
        this.rent = undefined;
        this.uploadedFiles = [];
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}