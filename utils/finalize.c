#include <stdio.h>
#include <libgen.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>
#include <fcntl.h>

#define DOUBLE_OPT "-d"

int main(int argc, char **argv)
{
    const uint8_t desiredChecksumValue = 1;
    const uint16_t checksumFixerOffset = 0x3FEB;
    const int halfSize = 16384;
    const int fullSize = halfSize * 2;

    uint8_t doubleSize = 0;
    char *in_filename = 0;
    char *out_filename = 0;
    int in_file = 0;
    int out_file = 0;
    uint16_t idx = 1;
    struct stat fileStat;
    uint8_t fileBuf[halfSize];
    uint8_t sum = 0;

    // read parameters until we've got everything we need
    while ((idx < argc) && (!in_filename || !out_filename))
    {
        if ((doubleSize == 0) && (strcmp(argv[idx], DOUBLE_OPT) == 0))
        {
            doubleSize = 1;
        }
        else if (!in_filename)
        {
            in_filename = argv[idx];
        }
        else if (!out_filename)
        {
            out_filename = argv[idx];
        }
        ++idx;
    };

    if (!in_filename || !out_filename)
    {
        printf("\n14CUX ROM Image Finalizer\nBalances the checksum value of a 16KB or 32KB ROM image for the 14CUX ECU.\n");
        printf("\nUsage: %s [options] input-image output-image\n", basename(argv[0]));
        printf("Valid options:\n-d  Double the size of a 16KB input file, duplicating the ROM image in the upper half.\n");
        return 0;
    }

    if (stat(in_filename, &fileStat) != 0)
    {
        fprintf(stderr, "Error: Could not read file information for '%s'.\n", in_filename);
        return -1;
    }

    if ((fileStat.st_size == halfSize) || (fileStat.st_size == fullSize))
    {
        if ((fileStat.st_size == fullSize) && (doubleSize == 1))
        {
            printf("Warning: input file is already 32KB; ignoring -d option...\n");
            doubleSize = 0;
        }
    }
    else
    {
        fprintf(stderr, "Error: '%s' is not a 16KB or 32KB image.\n", in_filename);
        return -2;
    }

    if ((in_file = open(in_filename, O_RDONLY)) <= 0)
    {
        fprintf(stderr, "Error: could not open input file '%s' (%s)\n", in_filename, strerror(errno));
        return -3;
    }

    if (read(in_file, fileBuf, halfSize) != halfSize)
    {
        fprintf(stderr, "Error: could not read input file '%s' (%s)\n", in_filename, strerror(errno));
        close(in_file);
        return -4;
    }

    close(in_file);

    if ((out_file = open(out_filename, O_WRONLY | O_CREAT, S_IRUSR | S_IWUSR)) <= 0)
    {
        fprintf(stderr, "Error: could not open output file '%s' (%s)\n", out_filename, strerror(errno));
        close(in_file);
        return -5;
    }

    for (idx = 0; idx < halfSize; ++idx)
    {
        sum += fileBuf[idx];
    }
    printf("Current 8-bit checksum is: 0x%02X, correcting...\n", sum);
    fileBuf[checksumFixerOffset] -= sum - desiredChecksumValue;

    if (write(out_file, (void*)fileBuf, halfSize) != halfSize)
    {
        fprintf(stderr, "Error: could not write output file '%s' (%s)\n", out_filename, strerror(errno));
        close(out_file);
        return -6;
    }

    if (doubleSize == 1)
    {
        printf("Duplicating image in upper 16KB half...\n");
        lseek(out_file, 0, SEEK_END);

        if (write(out_file, (void*)fileBuf, halfSize) != halfSize)
        {
            close(out_file);
            fprintf(stderr, "Error: could not write file '%s' (%s)\n", out_filename, strerror(errno));
            return -7;
        }
    }

    printf("Done.\n");
    close(out_file);

    return 0;
}

