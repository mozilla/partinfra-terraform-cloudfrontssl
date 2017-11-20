'use strict';

exports.handler = (event, context, callback) => {
    const response = event.Records[0].cf.response;
    const headers = response.headers;

    // See https://wiki.mozilla.org/Security/Guidelines/Web_Security
    ${hsts ? "headers['Strict-Transport-Security'] = [{'key': 'Strict-Transport-Security', 'value': 'max-age=63072000'}];" : ""}
    ${x-content-type ? "headers['X-Content-Type-Options'] = [{'key': 'X-Content-Type-Options', 'value': 'nosniff'}];" : ""}
    ${x-frame-options ? "headers['X-Frame-Options'] = [{'key': 'X-Frame-Options', 'value': 'DENY'}];" : ""}
    ${x-xss-protection ? "headers['X-XSS-Protection'] = [{'key': 'X-XSS-Protection', 'value': '1; mode=block'}];" : ""}
    callback(null, response);
};
