import { LightningElement, track, wire } from 'lwc';
import getProperties from '@salesforce/apex/PropertyController.getProperties';

export default class PropertyList extends LightningElement {
    @track properties = [];
    @track error;

    pageNumber = 1;
    pageSize = 25;
    totalCount = 0;

    // Filter values bound to inputs
    maxPrice;
    availabilityStatus;
    furnishingStatus;

    availabilityOptions = [
        { label: 'All', value: '' },
        { label: 'Available', value: 'Available' },
        { label: 'Occupied', value: 'Occupied' }
    ];

    furnishingOptions = [
        { label: 'All', value: '' },
        { label: 'Furnished', value: 'Furnished' },
        { label: 'Semi-Furnished', value: 'Semi-Furnished' },
        { label: 'Unfurnished', value: 'Unfurnished' }
    ];

    connectedCallback() {
        this.loadPage();
    }

    loadPage() {
        getProperties({
            pageNumber: this.pageNumber,
            pageSize: this.pageSize,
            maxPrice: this.maxPrice ? parseFloat(this.maxPrice) : null,
            availabilityStatus: this.availabilityStatus || null,
            furnishingStatus: this.furnishingStatus || null
        })
            .then((result) => {
                this.properties = result.records;
                this.totalCount = result.totalCount;
                this.error = undefined;
            })
            .catch((err) => {
                this.error = err;
                this.properties = [];
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
}