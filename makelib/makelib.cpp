#include <iostream>
#include <fstream>
#include <filesystem>
#include <sstream>
#include <string>


void write_16bits(std::ofstream& libfile, int data)
{
    unsigned char byte;

    byte = (unsigned char)(data & 255);
    libfile.write((char*)&byte, 1);
    byte = (unsigned char)((data >> 8) & 255);
    libfile.write((char*)&byte, 1);
}

void write_24bits(std::ofstream& libfile, int data)
{
    write_16bits(libfile, data);

    unsigned char byte = (unsigned char)((data >> 16) & 255);
    libfile.write((char*)&byte, 1);
}

void copy_files_to_library(std::ofstream& libfile, std::vector<std::string> files)
{
    for (auto &file : files)
    {
        std::ifstream input(file, std::ios::binary);

        std::copy(
            std::istreambuf_iterator<char>(input),
            std::istreambuf_iterator<char>(),
            std::ostreambuf_iterator<char>(libfile));
    }
}

/*
    Build the library's directory
    Format: 2 bytes: number of files in directory
            per file: 3 bytes: position in library
                      3 bytes: filesize
*/
int build_library_directory(std::ofstream& libfile, std::vector<std::string> files)
{
    //calculate position of first file in directory
    int file_pointer = 2 + 6 * (int)files.size();

    write_16bits(libfile, (int)files.size());

    for (auto &file : files)
    {
        int file_size = (int)std::filesystem::file_size(file);

        std::cout << "Including " << file << " (" << file_size << " bytes)" << std::endl;

        write_24bits(libfile, file_pointer);
        write_24bits(libfile, file_size);

        file_pointer += (int)file_size;
    }

    return file_pointer;
}


std::vector<std::string> get_files_from_file(char* files_name)
{
    std::vector<std::string> files;

    std::ifstream infile(files_name);
    std::string line;

    while (std::getline(infile, line))
    {
        if (line.length() == 0) continue;
        if (line.at(0) == ';') continue;
        if (line.at(0) <= 32) continue;

        std::size_t index = line.find(':');
        if (index != std::string::npos)
            line = line.substr(0, index);

        files.push_back(line);
    }

    return files;
}


bool all_files_exist(std::vector<std::string> files)
{
    bool all_files_exist = true;

    for (auto &file: files)
    {
        if (!std::filesystem::exists(file))
        {
            std::cerr << "File " << file << " doesn't exist." << std::endl;
            all_files_exist = false;
        }
    }

    return all_files_exist;
}

bool all_options_are_valid(int argc, char* argv[])
{
    for (int i = 1; i < argc; i++)
    {
        if (argv[i][0] != '-') continue;

        if (strcmp(argv[i], "-l") != 0 && strcmp(argv[i], "-list") != 0
            && strcmp(argv[i], "-o") != 0 && strcmp(argv[i], "-output") != 0)
        {
            std::cerr << "Invalid option " << argv[i] << std::endl;
            return false;
        }

        if ((i + 1) == argc)
        {
            std::cerr << "Missing argument for option " << argv[i] << std::endl;
            return false;
        }

        if (strcmp(argv[i], "-l") == 0 || strcmp(argv[i], "-list") == 0)
        {
            if (!std::filesystem::exists(argv[i + 1]))
            {
                std::cerr << "List file " << argv[i + 1] << " doesn't exist." << std::endl;
                return false;
            }
        }
    }

    return true;
}

char* get_output_filename(int argc, char* argv[])
{
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-o") == 0 || strcmp(argv[i], "-output") == 0)
        {
            return argv[i + 1];
        }
    }

    return nullptr;
}

std::vector<std::string> get_files_from_arguments(int argc, char* argv[])
{
    std::vector<std::string> files;

    for (int i = 1; i < argc; i++)
    {
        if (argv[i][0] == '-')
        {
            if (strcmp(argv[i], "-l") == 0 || strcmp(argv[i], "-list") == 0)
            {
                std::vector<std::string> files_from_file = get_files_from_file(argv[i + 1]);
                files.insert(files.end(), files_from_file.begin(), files_from_file.end());
            }

            i++;
        }
        else
        {
            files.push_back(argv[i]);
        }
    }

    return files;
}

int main(int argc, char* argv[])
{
    if (argc == 1)
    {
        std::cout << "Combines a set of specified files into one big file (library)." << std::endl;
        std::cout << "Usage:" << std::endl;
        std::cout << "makelib.exe -o <libfile.lib> [-l <list.txt>] [<file1> <file2> <...>]" << std::endl;
        std::cout << std::endl;
        std::cout << " -o <libfile.lib>  Filename of the resulting file" << std::endl;
        std::cout << " -outfile          Alias for -o" << std::endl;
        std::cout << " -l <list.txt>     Textfile containing a list of files to include" << std::endl;
        std::cout << "                   Each item must be specified on a new line" << std::endl;
        std::cout << "                   Lines may be empty" << std::endl;
        std::cout << "                   Lines may start with; to include remarks" << std::endl;
        std::cout << " -list             Alias for -l" << std::endl;
        std::cout << "Files to include in the library may also be specified as parameters" << std::endl;

        return 0;
    }

    if (!all_options_are_valid(argc, argv))
    {
        return 0;
    }

    char* library_filename = get_output_filename(argc, argv);

    if (library_filename == nullptr)
    {
        std::cerr << "No output file specified." << std::endl;
        return 0;
    }

    std::vector<std::string> files = get_files_from_arguments(argc, argv);

    if (files.size() == 0)
    {
        std::cerr << "No files to include in the library have been specified." << std::endl;
        return 0;
    }

    if (!all_files_exist(files))
    {
        return 0;
    }

    std::cout << "Start building library " << library_filename << "..." << std::endl;

    std::ofstream libfile(library_filename, std::ios::binary);
    int total_size = build_library_directory(libfile, files);
    copy_files_to_library(libfile, files);

    std::cout << "Finished building library!";
    std::cout << " (" << files.size() << " files, " << total_size << " bytes)" << std::endl;

    return 0;
}
