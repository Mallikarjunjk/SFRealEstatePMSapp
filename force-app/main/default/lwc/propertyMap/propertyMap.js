import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Property__c.Name',
    'Property__c.Address__c',
    'Property__c.Geolocation__Latitude__s',
    'Property__c.Geolocation__Longitude__s'
];

export default class PropertyMap extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    property;

    get mapMarkers() {
        if (!this.property.data) return [];

        const lat = this.property.data.fields.Geolocation__Latitude__s.value;
        const lng = this.property.data.fields.Geolocation__Longitude__s.value;

        if (lat == null || lng == null) return [];

        return [
            {
                location: {
                    Latitude: lat,
                    Longitude: lng
                },
                title: this.property.data.fields.Name.value,
                description: this.property.data.fields.Address__c.value
            }
        ];
    }

    get hasLocation() {
        return this.mapMarkers.length > 0;
    }
}