@isTest
global class GeocodingServiceMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[{"lat":"12.9716","lon":"77.5946"}]');
        res.setStatusCode(200);
        return res;
    }
}