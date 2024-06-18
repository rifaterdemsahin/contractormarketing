import time
import webbrowser

# Function to read URLs from a text file
def read_urls(filename):
    with open(filename, 'r') as file:
        urls = file.readlines()
    # Remove any whitespace characters like `\n` at the end of each line
    urls = [url.strip() for url in urls]
    return urls

# Main function to open URLs at intervals
def open_urls_at_intervals(filename, interval):
    urls = read_urls(filename)
    for url in urls:
        webbrowser.open(url)
        time.sleep(interval)

if __name__ == "__main__":
    filename = 'links.txt'
    interval = 10  # Interval in seconds
    open_urls_at_intervals(filename, interval)
