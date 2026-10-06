@IsTest
public class LeadIntegrationCalloutMock implements HttpCalloutMock {
    public Integer statusCode = 200;
    public String getBody =
        '{"results":[{"name":{"first":"Ada","last":"Lovelace"},"email":"ada.lovelace@example.com","phone":"555-0100","login":{"uuid":"ext-ada-1"},"location":{"city":"London"}}]}';

    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(statusCode);
        response.setStatus(statusCode == 200 ? 'OK' : 'Error');
        response.setHeader('uuid', 'wh-123');
        if (request.getMethod() == 'GET') {
            response.setBody(getBody);
        } else {
            response.setBody('ok');
        }
        return response;
    }
}
