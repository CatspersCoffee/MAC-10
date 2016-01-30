/* 

Description: obj_code_pkg.vhdl maker from Intel .HEX file
Date Created: 09-02-2013
First Revision: 
	Modifications:
					05-04-2015 Modified to read in Z80 intel hex and output MonZ80.vhd for SoCz80 project
	
Owner: Antony Brrows -  © 2013 ALL RIGHTS RESERVED

*/


#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>

void welcome_message();
void openHEX();
void displayHEX();
void print_header_to_VHDLfile();
int GetNextHEX_LineStartAddress();
void bytesInLine();

FILE *HEXFile;
FILE *vhdlFILE;

#define false = 0;
#define true = !flase;

char dummy[132000];//dummy array [number of lines] [number of characters];

char lines [2000][81];//char lines [number of lines] [number of characters]; - holds read in .hex file
int B = 0; //next HEX line start address
int lineNum = 0; //line in HEX to read from
int BytesinLine; //the number of bytes in the current line in the HEX file
int BytesTOTAL; //the total amount of Code Byte in the Program to be used in constant object_code : t_obj_code(0 to BytesTOTAL) := (

int main(void){
	int i;
	int CLSA, NLSA = 0; //CurrentLineStartAddress and NextLineStartAddress - for computation on NOP fill
	int EOP; //end of program
	int n;
	
	for(n=0; n<132000; n++){
		dummy[n] = 'G';
	}
	
	
	welcome_message();
	openHEX();

	displayHEX();
//	char c = getchar(); // TESTING 1
	
	vhdlFILE = fopen("MonZ80.vhd", "w+"); //create the new file
	
	print_header_to_VHDLfile();
	
	printf("\n");
	for(i=0; i<7; i++){
		printf("%c", lines [1][i]); //prints the address of the 2nd line in .hex file. 
	}
	
//	char c = getchar(); // TESTING 2	
	
	lineNum = 0;
	EOP = 0;
	int dumcharnum, dumcharnumE, chardummyA, chardummyB = 0;
	char dumchar;
	BytesTOTAL = 0;
	
	do {
	
		CLSA = GetNextHEX_LineStartAddress();
		bytesInLine();
		dumcharnum = 9;
		dumcharnumE = dumcharnum + (BytesinLine*2) - 1; //number to read up to in HEX file
		chardummyB = (BytesTOTAL*2); // the char# to write from in dummy
		chardummyA = chardummyB + (BytesinLine*2) - 1; //the char# to write to in dummy

				printf("\ndumcharnumE: %d", dumcharnumE);
				printf("\nchardummyB: %d (write from)", chardummyB);
				printf("\nchardummyA: %d (write to)", chardummyA);

		
		while (dumcharnum <= dumcharnumE){
			dumchar = lines[lineNum][dumcharnum];
			dummy[chardummyB] = dumchar;
			chardummyB++;
			dumcharnum++;
		}
		
		
		BytesTOTAL = BytesTOTAL + BytesinLine;
		lineNum++;
		NLSA = GetNextHEX_LineStartAddress();
		
		int Q, W, E = 0, R = 0;
		
		if( NLSA != 0 && lineNum > 0){
		//-------------------------------------------------------		
			
			if(CLSA == 0){
				R = -1;
			}
			if(CLSA > 0){
					R = 0;
				}
			Q = (NLSA + R); //where to write NOPs up to
			W = (CLSA + BytesinLine); //where to NOP from
			if(CLSA == 0){
				E = (Q-W + 1);
			}else if(CLSA > 0){
				E = (Q-W);
			}

		//-------------------------------------------------------				
			printf("\nNLSA: %X", NLSA);
			printf("\n\nQ: %d", Q);
			printf("\nW: %d", W);
			printf("\nE: %d (NOPfill Bytes)", E);
				
			if(E == 0){
				printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
			}
		}
		
		if( E > 0){
			int t, Y;
			Y = E*2;
			for(t=0; t<Y; t++){
			//	chardummyB; // the char# to write from in dummy
				chardummyA++; //the char# to write to in dummy
				dummy[chardummyA] = '0';
			}
			BytesTOTAL = BytesTOTAL + E;
			printf("\nchardummyB: %X (% d - write from)", chardummyB, chardummyB);
			printf("\nchardummyA: %X ( %d - write to)", chardummyA, chardummyA);
			printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
		}
		

		if( BytesTOTAL == 4096 ){
			EOP = 1;
			printf("\n ==> Max Number of Bytes for vhdl file reached!");			
		}			
		
		if( NLSA == 0 && lineNum > 0){
			EOP = 1;
			printf(" ==> End of Machine Code!");
		}
		
//	char c = getchar(); // TESTING 3		
		
	}while (EOP <= 0);

//	BytesTOTAL = BytesTOTAL + BytesinLine + NOPfill;
	

		printf("\n\nBytesTOTAL: %d", BytesTOTAL);
		printf("\n\n");
	
	fprintf(vhdlFILE, "\n");	
	
	int XCODE_SIZE = 0;
	if (BytesTOTAL <= 1024){
		XCODE_SIZE = 1024;
	}else if(BytesTOTAL <= 4096){
		XCODE_SIZE = 4096;
   }else{
     XCODE_SIZE = 8192;
   }

	fprintf(vhdlFILE, "\n");

	
	for(n=0; n<(BytesTOTAL*2) ; n++){
//		for(n=0; n<((BytesTOTAL*2) + 1); n++){
		printf("%c",dummy[n]);
	}
	
			n = BytesTOTAL;
			int BCx2 = -1;
			int BC = 0;
			int tnl = 0;
			while(BC != n){
			
			if(BC == 0){
				fprintf(vhdlFILE, "	");
			}
			if(BC != 0 && BC != n){
				fprintf(vhdlFILE, ", ");
			}
			if(tnl == 16){
				fprintf(vhdlFILE, "\n");
				fprintf(vhdlFILE, "	");
				tnl = 0;
			}
			
			BCx2++;
			fprintf(vhdlFILE, "X\"%c", dummy[BCx2]);
			BCx2++;
			fprintf(vhdlFILE, "%c\"", dummy[BCx2]);
			
			tnl++;
			BC++;
		}
	fprintf(vhdlFILE, "\n");	
	fprintf(vhdlFILE, ");\n");
		
	fprintf(vhdlFILE, "\n");
	fprintf(vhdlFILE, "\n");
		
//	 time_t mytime;
//    mytime = time(NULL);
  //  printf(ctime(&mytime));	
		
		
		
	fprintf(vhdlFILE, "	-- Bytes Total: %d  \n", BytesTOTAL);
//	fprintf(vhdlFILE, "	-- made: %s   \n", (ctime(&mytime)));	
	fprintf(vhdlFILE, "\n");
	fprintf(vhdlFILE, "\n");
		
	fprintf(vhdlFILE, "\n");		
	fprintf(vhdlFILE, "begin\n");	
	fprintf(vhdlFILE, "\n");		
	fprintf(vhdlFILE, "  ram_process: process(clk, byte_rom)\n");		
	fprintf(vhdlFILE, "  begin\n");		
	fprintf(vhdlFILE, "      if rising_edge(clk) then\n");		
	fprintf(vhdlFILE, "          -- latch the address, in order to infer a synchronous memory\n");
	fprintf(vhdlFILE, "          address_latch <= a;\n");
	fprintf(vhdlFILE, "      end if;\n");
	fprintf(vhdlFILE, "  end process;\n");
	fprintf(vhdlFILE, "\n");
	fprintf(vhdlFILE, "  d <= byte_rom(to_integer(unsigned(address_latch)));\n");
	fprintf(vhdlFILE, "\n");
	fprintf(vhdlFILE, "end arch;\n");
	fprintf(vhdlFILE, "\n");		
		
	int fclose (FILE *vhdlFILE);
}

void bytesInLine(){ //gets the number of bytes in the current HEX Line (to calculate
	//the amount of space before it has to fill up with 0x00 to the next start memory address
	//if applicable.
	char C; // the character just read in
	int n = 9;
	BytesinLine = 0;
	printf("\n");
	
	for(n=9; n<100; n++){
		C = lines[lineNum][n];
		
		printf("%c", C); //testing

		if( C == 10){
//			printf("\n n: %d", n);
//			printf("\nline feed");
			break;
		}
		BytesinLine++;
//		printf("\n BytesinLine: %d", BytesinLine);
	}
	
	BytesinLine = (BytesinLine/2) - 1;
	printf("\nCode Bytes: %d in Line: %d\n", BytesinLine, lineNum);
}



void openHEX(){
	int n;
//   HEXFile = fopen ("M2.HEX" , "r");
   HEXFile = fopen ("M2LV2.HEX" , "r");	
// HEXFile = fopen ("SOCM1.HEX" , "r");
//	HEXFile = fopen ("test6_2_0 test INTCONTROLLER.hex" , "r");
	
//	if (pFile == NULL){
//		printf("ERROR OPENING FILE!\n");
//		fclose (pFile);
//		return 1;
//	}
	for(n=0; n<223; n++){						//max amount of lines to read in from .hex file
		fgets (lines[n] , 81 , HEXFile);
	}
	fclose (HEXFile);
}

void displayHEX(){
	int i;
	i = 0;
	while(i < 40 ){
		printf("%s", lines[i]);
		i++;
	}
}

void welcome_message(){
	printf("Intel .HEX to .VHDL maker\n\n");
}
void print_header_to_VHDLfile(){
		fprintf(vhdlFILE, "--------------------------------------------------------------------------------\n");
		fprintf(vhdlFILE, "-- converts intel .hex into .vhd for SoCZ80 project\n");
		fprintf(vhdlFILE, "-- Generated by hex_to_vhdl_v2_0.exe\n");
		fprintf(vhdlFILE, "-- © 2013 Antony Burrows. All Rights Reserved.\n");
	
	
		fprintf(vhdlFILE, "--\n");	
		time_t mytime;
		mytime = time(NULL);

		fprintf(vhdlFILE, "-- .vhd file generated: %s", (ctime(&mytime)));	
		fprintf(vhdlFILE, "--\n");		
		fprintf(vhdlFILE, "--------------------------------------------------------------------------------\n");
		fprintf(vhdlFILE, "\n");
		fprintf(vhdlFILE, "\n");
		fprintf(vhdlFILE, "library ieee;\n");
		fprintf(vhdlFILE, "use ieee.std_logic_1164.all;\n");
		fprintf(vhdlFILE, "use ieee.numeric_std.all;\n");
		fprintf(vhdlFILE, "\n");	
		fprintf(vhdlFILE, "entity MonZ80 is\n");	
		fprintf(vhdlFILE, "   port(\n");
		fprintf(vhdlFILE, "      clk           : in  std_logic;\n");
		fprintf(vhdlFILE, "      a             : in  std_logic_vector(11 downto 0);\n");	
		fprintf(vhdlFILE, "      d             : out std_logic_vector(7 downto 0)\n");	
		fprintf(vhdlFILE, "   );\n");	
		fprintf(vhdlFILE, "end MonZ80;\n");
		fprintf(vhdlFILE, "\n");
		fprintf(vhdlFILE, "architecture arch of MonZ80 is\n");
		fprintf(vhdlFILE, "   constant byte_rom_WIDTH: integer := 8;\n");
		fprintf(vhdlFILE, "   type byte_rom_type is array (0 to 4095) of std_logic_vector(byte_rom_WIDTH-1 downto 0);\n");
		fprintf(vhdlFILE, "   signal address_latch : std_logic_vector(11 downto 0) := (others => '0');\n");
		fprintf(vhdlFILE, "\n");
		fprintf(vhdlFILE, "   -- actually memory cells\n");		
		fprintf(vhdlFILE, "   signal byte_rom : byte_rom_type := (\n");		
		fprintf(vhdlFILE, "   -- ROM contents follows\n");		
		fprintf(vhdlFILE, "\n");		
	
}

int GetNextHEX_LineStartAddress(){
	
	int A = 0;
	B = 0;
	int i=6;
	A = lines[lineNum][i];
	if(A >= 48  && A<= 57){
		A = A - 48;
	}
	if(A >= 65  && A<= 70){
		A = A - 55;
	}
	B = A;
	
	A = lines[lineNum][i-1];
	if(A >= 48  && A<= 57){
		A = A - 48;
		A = A *16;
	}
	if(A >= 65  && A<= 70){
		A = A - 55;
		A = A *16;
	}
	B = A + B;
	
	A = lines[lineNum][i-2];
	if(A >= 48  && A<= 57){
		A = A - 48;
		A = A *256;
	}
	if(A >= 65  && A<= 70){
		A = A - 55;
		A = A *256;
	}
	B = A + B;
	
	A = lines[lineNum][i-3];
	if(A >= 48  && A<= 57){
		A = A - 48;
		A = A *4096;
	}
	if(A >= 65  && A<= 70){
		A = A - 55;
		A = A *4096;
	}
	B = A + B;
	
	printf("\nStart address: 0x%X (d'%d') in Line: %d", B, B, lineNum);
	return B;
}
