import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProperties from '@salesforce/apex/PropertyController.getProperties';
import getThumbnails from '@salesforce/apex/PropertyController.getThumbnails';

export default class PropertyList extends NavigationMixin(LightningElement) {
    @track properties = [];
    @track error;
    isLoading = false;

    pageNumber = 1;
    pageSize = 25;
    totalCount = 0;

    maxPrice;
    availabilityStatus = '';
    furnishingStatus = '';

    availabilityOptions = [
        { label: 'All Statuses', value: '' },
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptions = [
        { label: 'All Furnishing Types', value: '' },
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    connectedCallback() {
        this.loadPage();
    }

    @api
    refresh() {
        this.pageNumber = 1;
        this.loadPage();
    }

    loadPage() {
        this.isLoading = true;
        getProperties({
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            maxPrice: this.maxPrice ? parseFloat(this.maxPrice) : null,
            availabilityStatus: this.availabilityStatus || null,
            furnishingStatus: this.furnishingStatus || null
        })
            .then((result) => {
                this.totalCount = result.totalCount;
                this.error = undefined;
                const ids = result.records.map((p) => p.Id);
                return getThumbnails({ propertyIds: ids }).then((thumbnails) => {
                    this.properties = result.records.map((p) => ({
                        ...p,
                        thumbnailUrl: thumbnails[p.Id] || null
                    }));
                });
            })
            .catch((err) => {
                this.error = err;
                this.properties = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get totalPages() {
        return Math.ceil(this.totalCount / this.pageSize) || 1;
    }

    get disablePrev() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber >= this.totalPages;
    }

    get hasResults() {
        return this.properties && this.properties.length > 0;
    }

    get paginationLabel() {
        return `Page ${this.pageNumber} of ${this.totalPages} (${this.totalCount} total)`;
    }

    handlePrev() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.loadPage();
        }
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.loadPage();
        }
    }

    handlePriceChange(event) {
        this.maxPrice = event.target.value;
        this.pageNumber = 1;
        this.loadPage();
    }

    handleAvailabilityChange(event) {
        this.availabilityStatus = event.target.value;
        this.pageNumber = 1;
        this.loadPage();
    }

    handleFurnishingChange(event) {
        this.furnishingStatus = event.target.value;
        this.pageNumber = 1;
        this.loadPage();
    }

    handleRowClick(event) {
        const propertyId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: propertyId,
                objectApiName: 'Property__c',
                actionName: 'view'
            }
        });
    }
}