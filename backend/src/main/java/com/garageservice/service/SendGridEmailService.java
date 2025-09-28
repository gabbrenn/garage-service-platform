package com.garageservice.service;

import com.sendgrid.Method;
import com.sendgrid.Request;
import com.sendgrid.Response;
import com.sendgrid.SendGrid;
import com.sendgrid.helpers.mail.Mail;
import com.sendgrid.helpers.mail.objects.Content;
import com.sendgrid.helpers.mail.objects.Email;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnProperty(name = "app.mail.provider", havingValue = "sendgrid")
public class SendGridEmailService implements EmailService {

    @Value("${app.mail.sendgrid.api-key:}")
    private String apiKey;

    @Value("${app.mail.from:no-reply@localhost}")
    private String fromAddress;

    @Value("${app.mail.enabled:true}")
    private boolean enabled;

    private void sendInternal(String to, String subject, String body, String mimeType) {
        if (!enabled) return;
        if (apiKey == null || apiKey.isBlank()) {
            System.err.println("[Email] SendGrid API key not configured; skipping email.");
            return;
        }
        try {
            Email from = new Email(fromAddress);
            Email toEmail = new Email(to);
            Content content = new Content(mimeType, body);
            Mail mail = new Mail(from, subject, toEmail, content);
            SendGrid sg = new SendGrid(apiKey);
            Request request = new Request();
            request.setMethod(Method.POST);
            request.setEndpoint("mail/send");
            request.setBody(mail.build());
            Response response = sg.api(request);
            int status = response.getStatusCode();
            if (status >= 200 && status < 300) {
                System.out.println("[Email] Sent to " + to + " subject=\"" + subject + "\"");
            } else {
                System.err.println("[Email] Failed to send: status=" + status + ", body=" + response.getBody());
            }
        } catch (Exception ex) {
            System.err.println("[Email] Exception while sending: " + ex.getMessage());
        }
    }

    @Override
    public void send(String to, String subject, String textBody) {
        sendInternal(to, subject, textBody, "text/plain");
    }

    @Override
    public void sendHtml(String to, String subject, String htmlBody) {
        sendInternal(to, subject, htmlBody, "text/html");
    }
}
