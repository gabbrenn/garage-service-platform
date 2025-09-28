package com.garageservice.service;

public interface EmailService {
    void send(String to, String subject, String textBody);
    void sendHtml(String to, String subject, String htmlBody);
}
