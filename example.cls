public with sharing class TestSendGridWithAttachments {

	public static void sendRequestToSendGrid(){

		List<Document> dd = [SELECT
			Id, Body, Name, BodyLength
			FROM Document
			WHERE DeveloperName IN ('testimage1', 'testpdf1') // change to yours document
		];

		String boundary = '----------------------------741e90d31eff';

		String header = '';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="api_user"\r\n\r\nYOUR_LOGIN\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="api_key"\r\n\r\nYOUR_PASSWORD\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="to"\r\n\r\nYOUR_EMAIL\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="from"\r\n\r\nFROM_EMAIL\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="fromname"\r\n\r\nSENDER_NAME\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="subject"\r\n\r\nSUBJECT\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="text"\r\n\r\nTEXT_BODY\r\n';
		header += '--'+boundary+'\r\n';
		header += 'Content-Disposition: form-data; name="html"\r\n\r\nHTML_BODY\r\n';

		String footer = '--'+boundary+'--';

		String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
		while(headerEncoded.endsWith('=')) {
			header += ' ';
			headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
		}

		String attachmentsStr = '';
		String lastPrepend = '';
		if (dd.size() > 0) {
			for (Document d : dd) {
				Blob fileBlob = d.Body;
				String filename = d.Name;
				String fHeader = lastPrepend + '--'+boundary+'\r\n';
				fHeader += 'Content-Disposition: form-data; name="files['+filename+']"; filename="'+filename+'"\r\nContent-Type: application/octet-stream';
				String fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fheader+'\r\n\r\n'));
				while(fHeaderEncoded.endsWith('=')) {
					fHeader += ' ';
					fHeaderEncoded = EncodingUtil.base64Encode(Blob.valueOf(fHeader+'\r\n\r\n'));
				}
				String fbodyEncoded = EncodingUtil.base64Encode(fileBlob);
				String last4Bytes = fbodyEncoded.substring(fbodyEncoded.length()-4,fbodyEncoded.length());
				if(last4Bytes.endsWith('==')) {
					last4Bytes = last4Bytes.substring(0,2) + '0K';
					fBodyEncoded = fbodyEncoded.substring(0,fbodyEncoded.length()-4) + last4Bytes;
					lastPrepend = '';
				} else if(last4Bytes.endsWith('=')) {
					last4Bytes = last4Bytes.substring(0,3) + 'N';
					fBodyEncoded = fbodyEncoded.substring(0,fbodyEncoded.length()-4) + last4Bytes;
					lastPrepend = '\n';
				} else {
					lastPrepend = '\r\n';
				}
				attachmentsStr += fHeaderEncoded + fBodyEncoded;
			}
			footer = lastPrepend + footer;
		} else {
			footer = '\r\n' + footer;
		}

		String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
		Blob bodyBlob = EncodingUtil.base64Decode(headerEncoded+attachmentsStr+footerEncoded);
		HttpRequest req = new HttpRequest();
		req.setHeader('Content-Type','multipart/form-data; boundary='+boundary);
		req.setMethod('POST');
		req.setEndpoint('https://api.sendgrid.com/api/mail.send.json');
		req.setBodyAsBlob(bodyBlob);
		req.setTimeout(120000);
		Http http = new Http();
		HTTPResponse res = http.send(req);
	}


}