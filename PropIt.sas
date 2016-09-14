/*--------------------------------------------------------------------------------------*

*******************************************************
***  Copyright Rho, Inc. 2016, all rights reserved  ***
*******************************************************

MACRO:       PropIt.sas

PURPOSE:     Propcase character variables while allowing for lowcase and upcase exceptions. Includes exception for first word of the character variable.

ARGUMENTS:   Var      => REQUIRED. Variable of interest
             ExLow    => OPTIONAL. List of words to exclude from lowercase exceptions to propcase. Enclose in %str().
             AddLow   => OPTIONAL. Additional lowercase exceptions to propcase. Enclose in %str(). 
             FFlag    => OPTIONAL. Flag denoting that the first word in every character string will be propcase.
             UpList   => OPTIONAL. Upcase exceptions to propcase. Enclose in %str(), include | delimiter.

OUTPUT:      &Var._Prop:  The propcase version of character variable allowing for user-specified exceptions.

Examples:
%PropIt(var=orgtxt,exlow=%str(but),addlow=%str(found|after),fflag=Y,uplist=%str(hiv|hcv));
%PropIt(var=orgtxt,exlow=,addlow=,fflag=,uplist=%str(hiv|hcv));


Program History:

DATE        PROGRAMMER          DESCRIPTION
---------   ------------------  ------------------------------------------------------
14JUL2016   Alex Buck            Create 


*--------------------------------------------------------------------------------------*/


%macro PropIt(var=,exlow=,addlow=,fflag=Y,uplist=);

   *Creating the lowercase the exeption list;

   %let LowList='';
   %let OrgLowList=%str(a|an|and|at|but|by|down|for|in|of|on|or|out|over|past|so|the|to|up|with|yet);
   %put Orginal LowList= &OrgLowList;

   %if &ExLow ne %then %do;
      %let LowList = %sysfunc(prxchange(s/\|(&ExLow)\b|\b(&ExLow)\|//i,-1,&OrgLowList));
      %put Lowlist with exception: &LowList;
      /* 
        s                  - begins the first argument to PRXCHANGE() and indicates regular expression is a search and replace
        /                  - opens search pattern 
        |                  - set | delimiter
        (&ExLow )          - looks ahead in the text string for the strings in &ExLow and returns a match
        \b                 - matches a word boundary after the word, e.g. matches between " " and "a" in "asdf "
        \b(&ExLow )        - looks ahead in the text string for the strings in &ExLow allowing for word boundary before word and returns a match
                             , e.g. matches between " " and "a" in " asdf"
        /                  - closes the search pattern and opens the replacement pattern
        /i,                - closes the replacement pattern and ends the first argument to PRXCHANGE()
                             i: performs case insentive search
                             /: No replacement values
        -1,                - performs the search and replace operation until no more matches are found
        &OrgLowList        - macro variable containing text string. lowcased for consistency
      */
   %end;

   %else %do;
      %let LowList=&OrgLowList;
   %end;

   %if &AddLow ne %then %do;
      %let LowList=%str(&LowList|&AddLow.);
   %end;

   %put LowList with Additions= &LowList;

   *Procase variable with lowcase exceptions;
   &Var._Prop = prxchange("s/\b(?!(?:&LowList)\b)([a-z])([a-z]+)\b/\U$1\L$2/i", -1, lowcase(&Var.));
      /* 
        's                 - begins the first argument to PRXCHANGE() and indicates regular expression is a search and replace
        /                  - opens search pattern 
        \b                 - matches a word boundary before the word, e.g. matches between " " and "a" in " asdf"
        (?!xxxxx)          - looks ahead in the text string for the strings in xxxxx and does not return a match (!)
        (?:&LowList)       - defines &lowlist as your non-capture group
        \b                 - matches a word boundary after the word - attached to non-capture group only
        ([a-z])            - matches a single lowercase letter and places the match in a "capture buffer" for reference in the replacement pattern
        ([a-z]+)           - matches one or more lowercase letters and places the match in a "capture buffer" for reference in the replacement pattern
        \b                 - matches a word boundary after the word - attached to capture groups
        /                  - closes the search pattern and opens the replacement pattern
        \U$1               - uppercases the first capture buffer, e.g. the single lowercase letter
        \L$2               - lowercases the second capture buffer, e.g. one or more lowercase letters
        /',                - closes the replacement pattern and ends the first argument to PRXCHANGE()
        -1,                - performs the search and replace operation until no more matches are found
        lowcase(&var.)    - variable containing text string. lowcased for consistency
      */

   %if &FFlag=Y %then %do;
      &Var._Prop=tranwrd(&Var._Prop,scan(&Var._Prop,1,' '),propcase(scan(&Var._Prop,1,' ')));
      /*
      tranwrd(source,target,replacement)    - replaces the first word in &Var._Prop with upcase(first word in &Var._Prop)
      scan(string,count,modifier)           - finds first word in &Var._Prop where space is the delimiter
      */

      %if &UpList ne %then %do;
         &Var._Prop=prxchange("s/\b(&UpList.)\b/\U$1/i",-1,&Var._Prop);
         /* 
         's                 - begins the first argument to PRXCHANGE() and indicates regular expression is a search and replace
         /                  - opens search pattern 
         \b                 - matches a word boundary before the word, e.g. matches between " " and "a" in " asdf"
         (&UpList)          - matches the strings in &uplist and places the match in a "capture buffer" for reference in the replacement pattern
         \b                 - matches a word boundary after the word
         /                  - closes the search pattern and opens the replacement pattern
         \U$1               - uppercases the first capture buffer, e.g. all strings found in &uplist.
         / ,                - closes the replacement pattern and ends the first argument to PRXCHANGE()
         i,                 - ignores case. 
         -1,                - performs the search and replace operation until no more matches are found
         &Var._Prop         - variable containing text string. 
         */
         %end;
   %end;

   %else %if &UpList ne %then %do;
      &Var._Prop=prxchange("s/\b(&UpList.)\b/\U$1/i",-1,&Var._Prop);
   %end;
   
%mend;
