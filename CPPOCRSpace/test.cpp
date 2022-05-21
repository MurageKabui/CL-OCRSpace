#include <iostream>
#include <istream>
#include <ostream>
#include <string>
#include <boost/asio.hpp>

using boost::asio::ip::tcp;
using namespace std;

int main(int argc, char* argv[])
{
    cout << "main -start" << endl;
    try
    {
        boost::asio::io_service io_service;
        string ipAddress = argv[1]; //"localhost" for loop back or ip address otherwise, i.e.- www.boost.org;       
        string portNum = argv[2]; //"8000" for instance;
        string hostAddress;
        if (portNum.compare("80") != 0) // add the ":" only if the port number is not 80 (proprietary port number).
        {
             hostAddress = ipAddress + ":" + portNum;
        }
        else 
        { 
            hostAddress = ipAddress;
        }
        string wordToQuery = "aha";
        string queryStr = argv[3]; //"/api/v1/similar?word=" + wordToQuery;

        // Get a list of endpoints corresponding to the server name.
        tcp::resolver resolver(io_service);
        tcp::resolver::query query(ipAddress, portNum);
        tcp::resolver::iterator endpoint_iterator = resolver.resolve(query);

        // Try each endpoint until we successfully establish a connection.
        tcp::socket socket(io_service);
        boost::asio::connect(socket, endpoint_iterator);

        // Form the request. We specify the "Connection: close" header so that the
        // server will close the socket after transmitting the response. This will
        // allow us to treat all data up until the EOF as the content.
        boost::asio::streambuf request;
        std::ostream request_stream(&request);
        request_stream << "GET " << queryStr << " HTTP/1.1\r\n";  // note that you can change it if you wish to HTTP/1.0
        request_stream << "Host: " << hostAddress << "\r\n";
        request_stream << "Accept: */*\r\n";
        request_stream << "Connection: close\r\n\r\n";

        // Send the request.
        boost::asio::write(socket, request);

        // Read the response status line. The response streambuf will automatically
        // grow to accommodate the entire line. The growth may be limited by passing
        // a maximum size to the streambuf constructor.
        boost::asio::streambuf response;
        boost::asio::read_until(socket, response, "\r\n");

        // Check that response is OK.
        std::istream response_stream(&response);
        std::string http_version;
        response_stream >> http_version;
        unsigned int status_code;
        response_stream >> status_code;
        std::string status_message;
        std::getline(response_stream, status_message);
        if (!response_stream || http_version.substr(0, 5) != "HTTP/")
        {
            std::cout << "Invalid response\n";
            return 1;
        }
        if (status_code != 200)
        {
            std::cout << "Response returned with status code " << status_code << "\n";
            return 1;
        }

        // Read the response headers, which are terminated by a blank line.
        boost::asio::read_until(socket, response, "\r\n\r\n");

        // Process the response headers.
        std::string header;
        while (std::getline(response_stream, header) && header != "\r")
        {
            std::cout << header << "\n";
        }

        std::cout << "\n";

        // Write whatever content we already have to output.
        if (response.size() > 0)
        {
            std::cout << &response;
        }

        // Read until EOF, writing data to output as we go.
        boost::system::error_code error;
        while (boost::asio::read(socket, response,boost::asio::transfer_at_least(1), error))
        {
              std::cout << &response;
        }

        if (error != boost::asio::error::eof)
        {
              throw boost::system::system_error(error);
        }
    }
    catch (std::exception& e)
    {
        std::cout << "Exception: " << e.what() << "\n";
    }

    return 0;
}