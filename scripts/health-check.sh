#!/bin/bash

# Helper function to test HTTP response for a given URL
test_http_response() {
    local url="$1"
    local description="$2"
    
    echo "   Testing: $description"
    local curl_output=$(curl -I -s --max-time 10 -w "%{http_code}" -o /dev/null "$url" 2>&1)
    local curl_exit_code=$?
    local status_code=$(echo "$curl_output" | tail -1)
    
    if [ $curl_exit_code -eq 0 ] && [[ "$status_code" =~ ^[0-9]{3}$ ]] && [ "$status_code" != "000" ]; then
        echo "   ✓ HTTP response successful (Status: $status_code)"
        return 0
    else
        echo "   ✗ HTTP response failed"
        if [ $curl_exit_code -ne 0 ]; then
            echo "     Error: $(echo "$curl_output" | head -1)"
        elif [ "$status_code" = "000" ]; then
            echo "     Error: Connection failed (Status: 000)"
        fi
        return 1
    fi
}

# Function to test hostname connectivity and HTTP responses
test_hostname() {
    local hostname="$1"
    local skip_ping="$2"
    local exit_code=0
    
    if [ -z "$hostname" ]; then
        echo "Error: Hostname argument is required"
        return 1
    fi
    
    echo "Testing hostname: $hostname"
    echo "================================"
    
    # Test ping (unless skipped)
    if [ "$skip_ping" != "true" ]; then
        echo "1. Testing ping to $hostname:"
        if ping -c 1 "$hostname" >/dev/null 2>&1; then
            echo "   ✓ Ping successful"
        else
            echo "   ✗ Ping failed"
            exit_code=1
        fi
        echo "2. Testing HTTP responses:"
    else
        echo "1. Testing HTTP responses:"
    fi
    
    # Test without protocol
    if ! test_http_response "$hostname" "$hostname"; then
        exit_code=1
    fi
    
    # Test with http://
    if ! test_http_response "http://$hostname" "http://$hostname"; then
        exit_code=1
    fi
    
    # Test with https://
    if ! test_http_response "https://$hostname" "https://$hostname"; then
        exit_code=1
    fi
    
    echo "================================"
    if [ $exit_code -eq 0 ]; then
        echo "All tests passed for $hostname"
    else
        echo "Some tests failed for $hostname"
    fi
    
    return $exit_code
}

# Main execution
main() {
    local skip_ping="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --no-ping)
                skip_ping="true"
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--no-ping]"
                echo "  --no-ping    Skip ping tests (useful for GitHub Actions)"
                echo "  -h, --help   Show this help message"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    local hostnames=(
        "degran.de"
        "www.degran.de"
        "niels.degran.de"
        "www.niels.degran.de"
    )
    
    local overall_exit_code=0
    
    echo "Testing all hostnames..."
    if [ "$skip_ping" = "true" ]; then
        echo "Ping tests will be skipped"
    fi
    echo "================================"
    echo
    
    for hostname in "${hostnames[@]}"; do
        test_hostname "$hostname" "$skip_ping"
        local test_exit_code=$?
        
        if [ $test_exit_code -ne 0 ]; then
            overall_exit_code=1
        fi
        
        echo
    done
    
    echo "================================"
    if [ $overall_exit_code -eq 0 ]; then
        echo "All hostnames passed all tests!"
    else
        echo "Some hostnames failed tests."
    fi
    
    return $overall_exit_code
}

# Run the main function with all command line arguments
main "$@"
