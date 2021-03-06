/*
 * Copyright (C) 2002  Erik Fears
 *
 *    QSTRING , ccomment and hashcomment taken from Hybrid7:
 *    Copyright (C) 2002 by the past and present ircd coders, and others.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to
 *
 *       The Free Software Foundation, Inc.
 *       59 Temple Place - Suite 330
 *       Boston, MA  02111-1307, USA.
 *
 *
 */

%option case-insensitive
%option noyywrap
%option nounput

%{
#include <stdio.h>
#include <string.h>
#include "config.h"
#include "config-parser.h"


void ccomment(void);
void hashcomment(void);

int linenum = 1;
char linebuf[512];

%}

string                 \"[^\"\n]*[\"\n]
comment                #.*
whitespace             [ \t\r]*

%%

"/*"                    { ccomment(); }

{comment}               { hashcomment(); }

{string}                {
                           /* QSTRING from Hybrid7. Why re-invent the wheel? */

                           if(yytext[yyleng-2] == '\\')
                           {
                              yyless(yyleng-1); /* return last quote */
                              yymore();         /* append next string */
                           }
                           else
                           {
                              yylval.string = yytext+1;
                              if(yylval.string[yyleng-2] != '"') ; /* log error */
                              else
                              {
                                 int i,j;

                                 yylval.string[yyleng-2] = '\0'; /* remove close
                                                                  *  quote
                                                                  */

                                 for (j=i=0 ;yylval.string[i] != '\0'; i++,j++)
                                 {
                                    if (yylval.string[i] != '\\')
                                    {
                                       yylval.string[j] = yylval.string[i];
                                    }
                                    else
                                    {
                                        i++;
                                        yylval.string[j] = yylval.string[i];
                                    }
                                 }
                                 yylval.string[j] = '\0';
                                 return STRING;
                              }
                           }

                        }

AWAY                    { return AWAY;         }
BAN_UNKNOWN             { return BAN_UNKNOWN;  }
BLACKLIST               { return BLACKLIST;    }
CHANNEL                 { return CHANNEL;      }
CONNREGEX               { return CONNREGEX;    }
DNS_FDLIMIT             { return DNS_FDLIMIT;  }
DNSBL_FROM              { return DNSBL_FROM;   }
DNSBL_TO                { return DNSBL_TO;     }
EXEMPT                  { return EXEMPT;       }
FD                      { return FD;           }
INVITE                  { return INVITE;       }
IRC                     { return IRC;          }
KLINE                   { return KLINE;        }
KEY                     { return KEY;          }
MASK                    { return MASK;         }
MAX_READ                { return MAX_READ;     }
MODE                    { return MODE;         }
NAME                    { return NAME;         }
NEGCACHE                { return NEGCACHE;     }
NICK                    { return NICK;         }
NICKSERV                { return NICKSERV;     }
OPER                    { return OPER;         }
OPM                     { return OPM;          }
OPTIONS                 { return OPTIONS;      }
PASSWORD                { return PASSWORD;     }
PERFORM                 { return PERFORM;      }
PIDFILE                 { return PIDFILE;      }
PORT                    { return PORT;         }
PROTOCOL                { return PROTOCOL;     }
REALNAME                { return REALNAME;     }
REPLY                   { return REPLY;        }
SCANLOG                 { return SCANLOG;      }
SCANNER                 { return SCANNER;      }
SENDMAIL                { return SENDMAIL;     }
SERVER                  { return SERVER;       }
TARGET_IP               { return TARGET_IP;    }
TARGET_PORT             { return TARGET_PORT;  }
TARGET_STRING           { return TARGET_STRING;}
TIMEOUT                 { return TIMEOUT;      }
TYPE                    { return TYPE;         }
USER                    { return USER;         }
USERNAME                { return USERNAME;     }
VHOST                   { return VHOST;        }
CYBNICK                 { return CYBNICK;      }
CYBHOST                 { return CYBHOST;      }
CYBIDENT                { return CYBIDENT;     }
AKILL                   { return AKILL;        }

HTTP                    {
                          yylval.number = OPM_TYPE_HTTP;
                          return PROTOCOLTYPE;
                        }

HTTPPOST                {
                          yylval.number = OPM_TYPE_HTTPPOST;
                          return PROTOCOLTYPE;
                        }

SOCKS4                  {
                          yylval.number = OPM_TYPE_SOCKS4;
                          return PROTOCOLTYPE;
                        }

SOCKS5                  {
                          yylval.number = OPM_TYPE_SOCKS5;
                          return PROTOCOLTYPE;
                        }

WINGATE                 {
                          yylval.number = OPM_TYPE_WINGATE;
                          return PROTOCOLTYPE;
                        }

ROUTER                  {
                          yylval.number = OPM_TYPE_ROUTER;
                          return PROTOCOLTYPE;
                        }


[0-9]+                  {
                           yylval.number=atoi(yytext);
                           return NUMBER;
                        }





TRUE                     {
                           yylval.number=1;
                           return NUMBER;
                         }
YES                      {
                           yylval.number=1;
                           return NUMBER;
                         }
ON                       {
                           yylval.number=1;
                           return NUMBER;
                         }



FALSE                    {
                           yylval.number=0;
                           return NUMBER;
                         }

NO                       {
                           yylval.number=0;
                           return NUMBER;
                         }

OFF                      {
                           yylval.number=0;
                           return NUMBER;
                         }



\n.*                    {
                           strcpy(linebuf, yytext+1);
                           linenum++;
                           yyless(1);
                        }

{whitespace}            /* ignore whitespace */;

.                       return yytext[0];

%%


void hashcomment(void)
{
}


/* C-comment ignoring routine -kre*/
void ccomment(void)
{
  int c;

  /* log(L_NOTICE, "got comment"); */
  while (1)
  {
     while ((c = input()) != '*' && c != EOF)
        if (c == '\n') ++linenum;
     if (c == '*')
     {
        while ((c = input()) == '*');
        if (c == '/') break;
     }
    if (c == EOF)
    {
       YY_FATAL_ERROR("EOF in comment");
       /* XXX hack alert this disables
        * the stupid unused function warning
        * gcc generates
        */
       if(1 == 0)
          yy_fatal_error("EOF in comment");
       break;
    }
  }
}

