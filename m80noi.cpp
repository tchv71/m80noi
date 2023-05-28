// m80noi.cpp : Этот файл содержит функцию "main". Здесь начинается и заканчивается выполнение программы.
//

#include <iostream>
#include <fstream>
#include <string.h>

int main(int argc, char** argv)
{
  if (argc == 1)
  {
    std::cout << "m80noi - m80 list file processor for NoICE" << '\n';
    std::cout << '\n' << "Usage: m80noi m80listfile.PRN" << "\n";
    return 0;
  }
  std::ifstream ifs;
  ifs.open(argv[1]);
  char asmName[128];
  strcpy_s(asmName, argv[1]);
  strcat_s(asmName, ".ASM");
  std::ofstream ofs_asm(asmName);
  char noiName[128];
  strcpy_s(noiName, argv[1]);
  char* pExt = strrchr(noiName, '.');
  if (pExt)
    *pExt = 0;
  strcat_s(noiName, ".NOI");
  std::ofstream ofs_noi(noiName);
  if (!argv[1] || !ifs.is_open())
  {
    std::cerr << "File " << argv[1] << " not found";
    return 0;
  }
  ofs_noi << "CLEARLINEINFO Y\n";
  ofs_noi << "FILE " << asmName << '\n';

  char linebuf[2048];
  int skipline = 0;
  int lineNo = 1;
  while (!ifs.eof())
  {
    ifs.getline(linebuf, sizeof(linebuf));
    if (skipline != 0)
    {
      skipline--;
      continue;
    }
    if (linebuf[0] == '\f')
    {
      size_t s = strlen(linebuf);
      if (s>6 && strcmp(linebuf+s-6 , "PAGE\tS")==0)
        break;
      skipline = 2;
      continue;
    }
    if (linebuf[2] != ' ' && linebuf[10] != ' ')
    {
      char addr[5];
      strncpy_s(addr, linebuf+2, 4);
      ofs_noi << "LINE " << lineNo << " " << addr << '\n';
    }
    const char* asmLine = linebuf + 26+6;
    //if (asmLine[0] == '+')
    //  asmLine++;
    ofs_asm << asmLine << '\n';
    lineNo++;
  }
}

