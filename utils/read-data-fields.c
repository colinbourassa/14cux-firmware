#include <stdio.h>
#include <libgen.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define OLD_FUEL_MAP_1_OFFSET 0x023F
#define NEW_FUEL_MAP_1_OFFSET 0x0267
#define REV_B_MAIN_VOLTAGE_FACTOR_A_OFFSET 0x079B
#define ROMSIZE 16384
#define OUTPUT_BYTES_PER_ROW 16

typedef struct
{
    uint16_t offset;
    uint16_t sizeBytes;
    const char* name;
} FIELD;

typedef enum
{
    Unset,
    RevA,
    RevB,
    RevC
} REVISION;

static FIELD fieldsRevA[] =
{
    { 0x023F, 130, "Fuel Map 1" },
    { 0x0351, 130, "Fuel Map 2" },
    { 0x0463, 130, "Fuel Map 3" },
    { 0x0575, 130, "Fuel Map 4" },
    { 0x0687, 130, "Fuel Map 5" },
    { 0x0000, 0,   "" }
};

static FIELD fieldsRevB[] =
{
    { 0x023F, 130, "Fuel Map 1" },
    { 0x0351, 130, "Fuel Map 2" },
    { 0x0463, 130, "Fuel Map 3" },
    { 0x0575, 130, "Fuel Map 4" },
    { 0x0687, 130, "Fuel Map 5" },
    { 0x0000, 0,   "" }
};

static FIELD fieldsRevC[] =
{
    { 0x0267, 130, "Fuel Map 1" },
    { 0x0379, 130, "Fuel Map 2" },
    { 0x048B, 130, "Fuel Map 3" },
    { 0x059D, 130, "Fuel Map 4" },
    { 0x06AF, 130, "Fuel Map 5" },
    { 0x0000, 0,   "" }
};

static FIELD fieldsCommon[] =
{
    { 0x0000, 130, "Fuel Map 0" },
    { 0x3FE9, 2,   "Tune revision" },
    { 0x3FEC, 2,   "Ident bytes" },
    { 0x0000, 0,   "" }
};

REVISION determineDataOffsets(uint8_t* buffer)
{
    REVISION rev = Unset;
    uint8_t maxByteToByteChangeOld = 0;
    uint8_t maxByteToByteChangeNew = 0;
    int firstRowOffset = 1;

    // these pointers are treated as arrays of the first 16 bytes of
    // the possible locations of the fuel maps
    uint8_t *testBufferOld = buffer + OLD_FUEL_MAP_1_OFFSET;
    uint8_t *testBufferNew = buffer + NEW_FUEL_MAP_1_OFFSET;

    // find the greatest byte-to-byte difference in each set of data
    for (firstRowOffset = 1; firstRowOffset < 16; firstRowOffset++)
    {
        if (maxByteToByteChangeOld <
                abs((testBufferOld[firstRowOffset] - testBufferOld[firstRowOffset - 1])))
        {
            maxByteToByteChangeOld =
                abs((testBufferOld[firstRowOffset] - testBufferOld[firstRowOffset - 1]));
        }

        if (maxByteToByteChangeNew <
                abs((testBufferNew[firstRowOffset] - testBufferNew[firstRowOffset - 1])))
        {
            maxByteToByteChangeNew =
                abs((testBufferNew[firstRowOffset] - testBufferNew[firstRowOffset - 1]));
        }
    }

    // real fuel map data will only have small changes between
    // consecutive values, so the run of data with the smallest
    // byte-to-byte changes is probably the real fuel map
    if (maxByteToByteChangeOld < maxByteToByteChangeNew)
    {
        // very old 14CU(X) units (1990ish and earlier) have some of the main-voltage
        // computation factors hardcoded, so we need to check for that as well
        if (buffer[REV_B_MAIN_VOLTAGE_FACTOR_A_OFFSET] == 0xFF)
        {
            rev = RevA;
        }
        else
        {
            rev = RevB;
        }
    }
    else
    {
        rev = RevC;
    }

    return rev;
}

void printHex(uint8_t* buffer, uint16_t sizeBytes)
{
    uint16_t idx = 0;
    for (idx = 0; idx < sizeBytes; ++idx)
    {
        if ((idx != 0) && (idx % OUTPUT_BYTES_PER_ROW == 0))
        {
            printf("\n");
        }
        printf("%02X ", buffer[idx]);
    }
    printf("\n");
}

int main(int argc, char **argv)
{
    int index = 0;
    REVISION rev = Unset;
    int fp = 0;
    uint8_t buffer[ROMSIZE];
    FIELD* fields = 0;
    int returnVal = 0;

    if (argc < 2)
    {
        printf("Usage: %s image-file.bin\n", basename(argv[0]));
        return 0;
    }

    if ((fp = open(argv[1], O_RDONLY)) > 0)
    {
        if (read(fp, buffer, ROMSIZE) == ROMSIZE)
        {
            rev = determineDataOffsets(buffer);
            if (rev == RevA)
            {
                printf("Image revision: Rev A (early data locations, hardcoded main voltage coefficients)\n");
                fields = fieldsRevA;
            }
            else if (rev == RevB)
            {
                printf("Image revision: Rev A (early data locations, main voltage coefficients in data segment)\n");
                fields = fieldsRevB;
            }
            else
            {
                printf("Image revision: Rev C (later data locations, main voltage coefficients in data segment)\n");
                fields = fieldsRevC;
            }

            while (fieldsCommon[index].sizeBytes)
            {
                printf("\n%s (%s)\n", fieldsCommon[index].name, argv[1]);
                printHex(&buffer[fieldsCommon[index].offset], fieldsCommon[index].sizeBytes);
                index += 1;
            }
            index = 0;
            while (fields[index].sizeBytes)
            {
                printf("\n%s (%s)\n", fields[index].name, argv[1]);
                printHex(&buffer[fields[index].offset], fields[index].sizeBytes);
                index += 1;
            }
        }
        else
        {
            fprintf(stderr, "Error: unable to read %d bytes from file (%s).\n", ROMSIZE, argv[1]);
            returnVal = -1;
        }
    }
    else
    {
        fprintf(stderr, "Error: unable to open file (%s).\n", argv[1]);
        returnVal = -2;
    }

    return returnVal;
}

