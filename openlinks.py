import time
import webbrowser
import re
import logging

# Configure logging to output to console
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Function to read URLs from a text file and filter out non-URLs
def read_urls(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()
    # Regular expression to match URLs
    url_pattern = re.compile(
        r'^(?:http|ftp)s?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|'  # ...or ipv4
        r'\[?[A-F0-9]*:[A-F0-9:]+\]?)'  # ...or ipv6
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)
    urls = [line.strip() for line in lines if url_pattern.match(line.strip())]
    return urls

# Main function to open URLs at intervals
def open_urls_at_intervals(filename, interval):
    urls = read_urls(filename)
    firefox_path = 'C:/Program Files/Mozilla Firefox/firefox.exe %s'
    for index, url in enumerate(urls):
        webbrowser.get(firefox_path).open(url)
        logging.info(f"Opened URL: {url}")
        time.sleep(interval)
        logging.info(f"Waiting for {interval} seconds before opening the next URL.")
    logging.info("Finished opening all URLs.")

if __name__ == "__main__":
    filename = 'C:\\Users\\Pexabo\\Desktop\\contractormarketing\\links.txt'
    interval = 10  # Interval in seconds
    open_urls_at_intervals(filename, interval)
