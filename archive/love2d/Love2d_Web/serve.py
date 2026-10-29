#!/usr/bin/env python3
"""
Simple HTTP server with cross-origin isolation headers for love.js
"""
import http.server
import socketserver
import os
import sys

PORT = 3000

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add cross-origin isolation headers for SharedArrayBuffer support
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Content-Security-Policy', "default-src 'self' https:; script-src 'self' 'unsafe-eval' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:")
        super().end_headers()

    def log_message(self, format, *args):
        print(f"[{self.log_date_time_string()}] {format % args}")

if __name__ == '__main__':
    os.chdir('Love2d_Web/dist')
    
    with socketserver.TCPServer(("", PORT), CORSRequestHandler) as httpd:
        print(f"🎣 Serving Hopeless Catch at http://localhost:{PORT}/")
        print(f"📁 Serving from: {os.getcwd()}")
        print(f"Press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n✅ Server stopped")
            sys.exit(0)
