import smtplib
from email.mime.text import MIMEText

def send_email(to_email, subject, body):
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = 'fibladievent@gmail.com'  # <-- replace with your Gmail
    msg['To'] = to_email

    # Connect to Gmail SMTP server
    with smtplib.SMTP('smtp.gmail.com', 587) as server:
        server.starttls()  # Secure the connection
        server.login('fibladievent@gmail.com', 'bprxmznlabotgkkq')  # <-- put your app password
        server.send_message(msg)
