import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import jsPDFResource from '@salesforce/resourceUrl/jsPDF';
import getLeaseDetails from '@salesforce/apex/LeaseAgreementController.getLeaseDetails';
import sendLeasePdf from '@salesforce/apex/LeaseAgreementController.sendLeasePdf';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeaseAgreementPdf extends LightningElement {
    @api recordId;
    jsPDFInitialized = false;
    isLoading = false;

    renderedCallback() {
        if (this.jsPDFInitialized) return;
        this.jsPDFInitialized = true;
        loadScript(this, jsPDFResource)
            .then(() => {})
            .catch((err) => {
                this.showToast('Error', 'Could not load PDF library: ' + err.message, 'error');
            });
    }

    async buildPdfDoc() {
        const lease = await getLeaseDetails({ leaseId: this.recordId });
        // eslint-disable-next-line no-undef
        const { jsPDF } = window.jspdf;
        const doc = new jsPDF();

        doc.setFontSize(18);
        doc.text('Lease Agreement', 20, 20);

        doc.setFontSize(11);
        doc.text(`Property: ${lease.propertyName}`, 20, 35);
        doc.text(`Tenant: ${lease.tenantName}`, 20, 42);
        doc.text(`Monthly Rent: ${lease.rent}`, 20, 49);
        doc.text(`Start Date: ${lease.startDate}`, 20, 56);
        doc.text(`End Date: ${lease.endDate}`, 20, 63);
        doc.text('Terms:', 20, 73);
        doc.text(lease.terms || '', 20, 80, { maxWidth: 170 });

        return doc;
    }

    async handleDownload() {
        try {
            this.isLoading = true;
            const doc = await this.buildPdfDoc();
            doc.save(`Lease_Agreement_${this.recordId}.pdf`);
        } catch (err) {
            this.showToast('Error', 'Could not generate PDF: ' + err.body?.message || err.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleSendEmail() {
        try {
            this.isLoading = true;
            const doc = await this.buildPdfDoc();
            const base64 = doc.output('datauristring').split(',')[1];
            await sendLeasePdf({ leaseId: this.recordId, base64Pdf: base64 });
            this.showToast('Success', 'Lease agreement emailed to tenant.', 'success');
        } catch (err) {
            this.showToast('Error', 'Could not send email: ' + (err.body?.message || err.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}