package com.garageservice.service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.stereotype.Service;

@Service
@ConditionalOnMissingBean(SendGridEmailService.class)
public class NoopEmailService implements EmailService {
    @Override
    public void send(String to, String subject, String textBody) {
        System.out.println("[Email noop] would send to=" + to + " subject=\"" + subject + "\"");
    }

    @Override
    public void sendHtml(String to, String subject, String htmlBody) {
        System.out.println("[Email noop] would send HTML to=" + to + " subject=\"" + subject + "\"");
    }
}
