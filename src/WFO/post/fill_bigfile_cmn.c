#include <config.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <unistd.h>
#include <netcdf.h>
#include "fill_bigfile.h"

/******************************************************************/
int fillWFOlevels(int numWFOlevels, char *WFOlevels_char,
                  WFO_LEVELS_T *WFOlevels)
{
    int i;
    char c_level_value[10], *c_ptr;

    for (i = 0; i < numWFOlevels; i++) {
      c_ptr = WFOlevels_char + (i * CHARS_PER_LEVEL);
      if ((strncmp(c_ptr,"SFC",3) == 0) ||
          (strncmp(c_ptr,"MSL",3) == 0)) {
        strncpy(WFOlevels[i].WFO_level,c_ptr,3);
        WFOlevels[i].WFO_level[3] = '\0';
        WFOlevels[i].WFO_level_value = 0;
      }
      else {
        if ((strncmp(c_ptr,"MB",2) == 0) ||
            (strncmp(c_ptr,"BLS",3) == 0) ||
            (strncmp(c_ptr,"FH",2) == 0)) {
          sscanf(c_ptr, "%s %s", 
                        WFOlevels[i].WFO_level,
                        c_level_value);
          WFOlevels[i].WFO_level_value = (short)atoi(c_level_value);
        }
        else {
          return ERROR;
        }
      }
    }
    return SUCCESS;
}

/******************************************************************/
int findWFOindex(int numWFOlevels, WFO_LEVELS_T *WFOlevels,
                 char *WFO_level, char *WFO_level_value, float *level_ptr)
{
    int i, found, returnIndex;
    float findLevel, level_val;

    found = FALSE;
    i = 0;
    if ((strncmp(WFO_level,"SFC",3) == 0) && (*level_ptr == 0)) {
      while ((found == FALSE) && (i < numWFOlevels)) {
        if (strncmp(WFOlevels[i].WFO_level,"SFC",3) == 0) {
          returnIndex = i;
          found = TRUE;
        }
        i++;
      }
    }
    if ((strncmp(WFO_level,"MSL",3) == 0) && (*level_ptr == 0)) {
      while ((found == FALSE) && (i < numWFOlevels)) {
        if (strncmp(WFOlevels[i].WFO_level,"MSL",3) == 0) {
          returnIndex = i;
          found = TRUE;
        }
        i++;
      }
    }
    if ((strncmp(WFO_level,"FH",2) == 0) && (*level_ptr == 0)) {
      findLevel = (short)atoi(WFO_level_value);
      while ((found == FALSE) && (i < numWFOlevels)) {
        if (strncmp(WFOlevels[i].WFO_level,"FH",2) == 0) {
          if (findLevel == WFOlevels[i].WFO_level_value) {
            returnIndex = i;
            found = TRUE;
          }
        }
        i++;
      }
    }
    if (strncmp(WFO_level,"BLS",3) == 0) {
      level_val = *level_ptr * (-1);
      while ((found == FALSE) && (i < numWFOlevels)) {
        if ((strncmp(WFOlevels[i].WFO_level,"BLS",3) == 0) &&
            (WFOlevels[i].WFO_level_value == level_val)) {
          returnIndex = i;
          found = TRUE;
        }
        i++;
      }
    }
    if (strncmp(WFO_level,"MB",2) == 0) {
      while ((found == FALSE) && (i < numWFOlevels)) {
        if ((strncmp(WFOlevels[i].WFO_level,"MB",2) == 0) &&
            (WFOlevels[i].WFO_level_value == *level_ptr)) {
          returnIndex = i;
          found = TRUE;
        }
        i++;
      }
    }

    if (found == TRUE) 
      return (returnIndex);
    else 
      return (-1);

}

/******************************************************************/
int extractLAPSdata(int *cdfId_in, char *prevFilename, PARAMETER_LIST_T paramInfo, 
                    char *r_filename, time_t reftime, time_t valtime, 
                    int *x, int *y, int *numLevels, float **level,
                    float **data, short **LAPSinv)
{
    char filename[80];
    int cdfId, mode = NC_NOWRITE, status;    
    double d_reftime=0.0, d_valtime=0.0;
    ncopts = 0;
    
    status = get_LAPS_cdf_filename(paramInfo, r_filename, reftime, filename);

    cdfId = *cdfId_in;
    if (strcmp(filename, prevFilename) != 0) {  /* new file */
      ncclose(cdfId);
      free(data);
      free(LAPSinv);
      free(level);

      if( access(filename, F_OK) != 0 ) {
        fprintf(stdout,"The LAPS file %s does not exist\n",filename);
        return ERROR;
      }
     
      cdfId = ncopen ((const char *)filename, mode);     
      if(cdfId == NC_SYSERR) {
        fprintf(stdout,"Error opening LAPS file %s\n",filename);
        return ERROR;
      }

      *cdfId_in = cdfId;
      strcpy(prevFilename, filename);
        
      status = getDataSize(cdfId, paramInfo.LAPS_level_name, x, y, numLevels);
      if (status == ERROR) return ERROR;
 
      if(*numLevels == 1) {
        *data = (float *)malloc((*x)*(*y)*sizeof(float));
        *LAPSinv = (short *)malloc(sizeof(short));
        *level = (float *)malloc(sizeof(float));
      }
      else {
        *data = (float *)malloc((*x)*(*y)*(*numLevels)*sizeof(float));
        *LAPSinv = (short *)malloc((*numLevels)*sizeof(short));
        *level = (float *)malloc((*numLevels)*sizeof(float));
      }
    }
    
    status = getLAPSdata(cdfId, d_reftime, d_valtime, 
               paramInfo.LAPS_cdl_varname, *x, *y, *numLevels, 
               level, data, LAPSinv);
    
/*    reftime = (time_t)d_reftime;
    valtime = (time_t)d_valtime; */
 
    if (status == ERROR) {
      return ERROR;
    }
    else {
      return SUCCESS;
    }

}

/******************************************************************/
int getDataSize(int cdfId, char *level_name, int *x, int *y, int *numLevels)
{
    int xId, yId, zId;
    long long_x, long_y, long_lvl;

    xId = ncdimid(cdfId, (const char *)"x");
    yId = ncdimid(cdfId, (const char *)"y");
    zId = ncdimid(cdfId, (const char *)level_name);
    if ((xId == -1) || (yId == -1) || (zId == -1)) {
      fprintf(stdout, "Error getting x,y or z dimensions from LAPS file.\n");
      return ERROR;
    }
    
    ncdiminq(cdfId, xId, (char *) 0, (long *)&long_x);
    ncdiminq(cdfId, yId, (char *) 0, (long *)&long_y);
    ncdiminq(cdfId, zId, (char *) 0, (long *)&long_lvl);
 
    *x = (int)long_x;
    *y = (int)long_y;
    *numLevels = (int)long_lvl;

    return SUCCESS;
}

/******************************************************************/
int getLAPSdata(int cdfId, double reftime, double valtime, const char *variable, 
                int x, int y, int numLevels, float **level, float **data, short **inv)
{
    int varId, invId, levelId, xstatus;
    long start[5], count[5], invStart[3], invCount[3], levelStart[1], levelCount[1];
    char invVar[15];

    start[0] = 0;
    start[1] = 0;
    start[2] = 0;
    start[3] = 0;
    
    count[0] = 1;
    count[1] = numLevels;
    count[2] = y;
    count[3] = x;
    
    varId = ncvarid(cdfId,(const char *)variable);
    ncvarget(cdfId, varId, (const long *)start, (const long *)count, (void *) *data);

/* retrieve 'valtime' and 'reftime' data 
    varId = ncvarid(cdfId,(const char *)"valtime");
    ncvarget1(cdfId, varId, (const long *)start, (void *) &valtime);

    varId = ncvarid(cdfId,(const char *)"reftime");
    ncvarget1(cdfId, varId, (const long *)start, (void *) &reftime);
*/

/* make LAPS inventory variable name from "variable" */
    strcpy(invVar,variable);
    strcat(invVar,"_fcinv");
    
    invStart[0] = 0;
    invStart[1] = 0;

    invCount[0] = 1;
    invCount[1] = numLevels;

/* read LAPS inventory data */
    if ((invId = ncvarid(cdfId,(const char *)invVar)) == -1) {
      fprintf(stdout,"Error finding LAPS variable %s\n",invVar);
      return ERROR;
    }
    else if ((ncvarget(cdfId, invId, (const long *)invStart, 
              (const long *)invCount, (void *) *inv)) == -1) {
      fprintf(stdout,"Error reading LAPS variable %s\n",invVar);
      return ERROR;
    }

/* read LAPS level data */
    levelStart[0] = 0;
    levelCount[0] = numLevels;

    if ((levelId = ncvarid(cdfId,(const char *)"level")) == -1) {
      fprintf(stdout,"Error finding LAPS variable level\n");
      return ERROR;
    }
    else {
      xstatus = ncvarget(cdfId, levelId, (const long *)levelStart, 
                         (const long *)levelCount, (void *) *level);
      if (xstatus == -1) {
        fprintf(stdout,"Error reading LAPS variable level\n");
        return ERROR;
      }
    }

    return SUCCESS;
    
} 

/******************************************************************/
int openOutputWFOfile(long *index, time_t reftime, long *x, long *y)
{
    int cdfId, mode = NC_WRITE;
    int dimId, xstatus;
    char cdfFilename[80], templateFile[80];

    xstatus = get_WFO_cdf_filename(reftime, cdfFilename, templateFile);
 
    if( access(cdfFilename, F_OK) != 0 ) {
      if(copyTemplateToNewCDFfile (templateFile, cdfFilename) != SUCCESS) {
        return (-1);
      }
    }

    cdfId = ncopen ((const char *)cdfFilename, mode);
    if(cdfId == NC_SYSERR) {
      fprintf(stdout,"Error opening WFO file %s\n",cdfFilename);
      return (-1);
    }
 
    else {
/*   determine the current value of "record"...use that as index,
       since record == 1 means the 0 index has been used, and the
       next one is 1  */
      dimId = ncdimid(cdfId, (const char *)"record");
      ncdiminq(cdfId, dimId, (char *) 0, (long *)index);

/*    read x and y dimensions in output file     */
      dimId = ncdimid(cdfId, (const char *)"x");
      ncdiminq(cdfId, dimId, (char *) 0, (long *)x);

      dimId = ncdimid(cdfId, (const char *)"y");
      ncdiminq(cdfId, dimId, (char *) 0, (long *)y);

      return cdfId;
    }
}

/******************************************************************/
int transferLAPStoWFO(int cdfId, long index, PARAMETER_LIST_T paramInfo, 
                      time_t reftime, time_t valtime, int x, int y, 
                      int numLevels, float **level, float **data, 
                      short **LAPSinv)
{
    double d_reftime, d_valtime;
    int fcst_status;
    
    d_reftime = (double)reftime;
    d_valtime = (double)valtime;

    fcst_status = storeLAPSdata(index, cdfId, d_reftime, d_valtime, 
                      paramInfo.WFO_cdl_varname, paramInfo.WFO_level_name,
                      paramInfo.WFO_level, paramInfo.WFO_level_value,
    		      x, y, numLevels, level, data, LAPSinv);
    
    return fcst_status;
}
    

/******************************************************************/
int storeLAPSdata(long index, int cdfId, double reftime, double valtime,
                  char *variable, char *levelName, char *WFO_level,
                  char *WFO_level_value, int x, int y, 
		  int numLevels, float **level, float **data, short **inv)
{
    int WFOvarId, WFOinvId, WFOlevelsId, dimId, numWFOlevels, WFOlevelIndex;
    int varId, i, inv_status;
    long varStart[4], varCount[4], invStart[2], invCount[2]; 
    long start[1], count[1], n_valtimes, valtimeMINUSreftime;
    char levelsVar[16], invVar[30], inv_char; 
    char *WFOlevels_char; 
    float *data_ptr, *level_ptr;
    short *inv_ptr;
    WFO_LEVELS_T WFOlevels[MAX_WFO_LEVELS];
    
    start[0] = index;

/* get value of n_valtimes, used to store inventory" */
    dimId = ncdimid(cdfId, (const char *)"n_valtimes");
    ncdiminq(cdfId, dimId, (char *) 0, (long *)&n_valtimes);

    if (index >= n_valtimes) {
      fprintf(stdout,"n_valtimes is less than index in CDL dimensions\n");
      return ERROR;
    }
    varId = ncvarid(cdfId,(const char *)"valtime");
    if(varId == -1)
        {
        fprintf(stdout,"Variable 'valtime' does not exist\n");
        return ERROR;
        }
 
    if((ncvarput1 (cdfId, varId, (const long *)start, (void *) &valtime)) == -1)
        {
        fprintf(stdout,"Error in ncvarput1 for 'valtime' variable.\n");
        return ERROR;
        }
 
    varId = ncvarid(cdfId,(const char *)"reftime");
    if(varId == -1)
        {
        fprintf(stdout,"Variable 'reftime' does not exist\n");
        return ERROR;
        }
 
    if((ncvarput1 (cdfId, varId, (const long *)start, (void *) &reftime)) == -1)
        {
        fprintf(stdout,"Error in ncvarput1 for 'reftime' variable.\n");
        return ERROR;
        }
 
    varId = ncvarid(cdfId,(const char *)"valtimeMINUSreftime");
    if(varId == -1)
        {
        fprintf(stdout,"Variable 'valtimeMINUSreftime' does not exist\n");
        return ERROR;
        }
 
    valtimeMINUSreftime = (long) valtime - reftime;
    if((ncvarput1 (cdfId, varId, (const long *)start, 
                   (void *) &valtimeMINUSreftime)) == -1) {
      fprintf(stdout,"Error in ncvarput1 for 'valtimeMINUSreftime' variable.\n");
      return ERROR;
    }
 
/* get number of levels in WFO for storing "variable" */
    dimId = ncdimid(cdfId, (const char *)levelName);
    ncdiminq(cdfId, dimId, (char *) 0, (long *)&numWFOlevels);

/* get var id's for "variable", and associated Levels and Inventory variables */
    strcpy(levelsVar, variable);
    strcat(levelsVar, "Levels");
    WFOlevelsId = ncvarid(cdfId,(const char *)levelsVar);
    if(WFOlevelsId == -1)
        {
        fprintf(stdout,"Error - WFO Variable %s does not exist\n", levelsVar);
        return ERROR;
        }

    strcpy(invVar, variable);
    strcat(invVar, "Inventory");
    WFOinvId = ncvarid(cdfId, (const char *)invVar);
    if(WFOinvId == -1)
        {
        fprintf(stdout,"WFO Variable %s does not exist\n", invVar);
        return ERROR;
        }

    WFOvarId = ncvarid(cdfId,(const char *)variable);
    if(WFOvarId == -1)
        {
        fprintf(stdout,"WFO Variable %s does not exist\n", variable);
        return ERROR;
        }
        
/* generate WFO_level structure from Levels variable */
    invStart[0] = 0;
    invStart[1] = 0;
    invCount[0] = numWFOlevels;
    invCount[1] = CHARS_PER_LEVEL;
    WFOlevels_char = (char *)malloc(numWFOlevels*CHARS_PER_LEVEL*sizeof(char));
    ncvarget(cdfId, WFOlevelsId, (const long *)invStart, 
             (const long *)invCount, (void *) WFOlevels_char);
    if (fillWFOlevels(numWFOlevels,WFOlevels_char, WFOlevels) != SUCCESS) {
      fprintf(stdout, "Cannot access %s \n", levelsVar);
      free(WFOlevels_char);
      return ERROR;
    }
    free(WFOlevels_char);

/* write data to WFO variable one level at a time */
    inv_ptr = *inv;
    level_ptr = *level;
    
    varStart[0] = index;
    varStart[2] = 0;
    varStart[3] = 0;

    varCount[0] = 1;
    varCount[1] = 1;
    varCount[2] = y;
    varCount[3] = x;

    invStart[0] = index;

    invCount[0] = 1;
    invCount[1] = 1;
    inv_status = SUCCESS;

    for (i = 0; i < numLevels; i++) {

      data_ptr = (*data + (x*y*i));

      WFOlevelIndex = findWFOindex(numWFOlevels,WFOlevels,WFO_level,
                                   WFO_level_value, level_ptr);
      if (WFOlevelIndex == (-1)) {
        fprintf(stdout,"Error finding level %4d to write out.\n", (int)*level_ptr);
      }
      else {
        if (*inv_ptr == 1) {
          inv_char = (char)49;  /* this writes the character "1" */

          varStart[1] = WFOlevelIndex;

          if((ncvarput(cdfId, WFOvarId, (const long *)varStart, 
                       (const long *)varCount, (void *) data_ptr)) == -1) { 
            fprintf(stdout,"Error in ncvarput for WFO %s - level %d\n", variable, (int)*level_ptr);
            inv_char = (char)0;  /* this writes a null */
          }
        }
        else {
          inv_char = (char)0;  /* this writes a null */
          inv_status = NOINV;
        }

        invStart[1] = WFOlevelIndex;

        if((ncvarput(cdfId, WFOinvId, (const long *)invStart, 
                     (const long *)invCount, (void *) &inv_char)) == -1) { 
          fprintf(stdout,"Error in ncvarput for WFO %sInventory - level %d\n", 
                  variable, (int)*level_ptr);
        }
      }

      level_ptr++;
      inv_ptr++;

    }
    
    return inv_status;
}

/******************************************************************/
int get_LAPS_cdf_filename (PARAMETER_LIST_T paramInfo, 
                           char *r_filename,
                           time_t obtime, 
                           char *filename)
{
    char timeString[MAX_TIMESTRING_LEN];
    char suffix[5]; 
    
    strcpy (filename, getenv ("FCSTPRD"));   /* HOME directory */
    strcat (filename, "/");
    strcat (filename, paramInfo.LAPS_dir_name);  /* file extension directory */
    strcat (filename, "/");
/* assume that r_filename is of the form: YYJJJHHXX where XX is hour of fcst
     ie. 952130604 = 06z model run, 4 hour forecast */
    strcat (filename, r_filename);
    strcat (filename,".");
    strcpy (suffix, paramInfo.LAPS_dir_name);
    strcat (filename, suffix);
 
    return SUCCESS;
}                           

/******************************************************************/
int get_WFO_cdf_filename (time_t obtime, char *filename, char *templateName)
    {
    char timeString[MAX_TIMESTRING_LEN];
    struct tm *time = gmtime (&obtime);
    
    strcpy (filename, getenv ("WFO_FCSTPRD"));   /* HOME directory */
    strcat (filename, "/");
    
    strcpy (templateName, filename);
    strcat(templateName, "template");
    
    strftime(timeString, MAX_TIMESTRING_LEN, "%Y%m%d_%H00", time);
    strcat (filename, timeString);
    
    return SUCCESS;
    }                           

/******************************************************************/
int get_transfer_parameter_list (PARAMETER_LIST_T *paramInfo, 
                                    int *numOfElements )
    {
    FILE *fp;
    char filename [100];
    char paramString[100];
    int i = 0;
    
    *numOfElements = 0;
    strcpy (filename, getenv ("TRANS_TBL"));
    
    if ((fp=fopen (filename, "r")) == (FILE *) 0)
        {
        /* fprintf (stdout, "s", strerror (errno)); */
        fprintf (stdout, "Unable to open %s\n", filename);
        return ERROR;
        }
        
    while (!(feof (fp)) && i < MAX_PARAMETER_LIST_LEN)
        {
        fgets (paramString, 100, fp);
        if (strlen (paramString) > 0  && paramString[0] != '#')
            {
            sscanf (paramString, "%s %s %s %s %s %s %s", 
                                 paramInfo[i].LAPS_dir_name,
                                 paramInfo[i].LAPS_cdl_varname,
                                 paramInfo[i].LAPS_level_name,
                                 paramInfo[i].WFO_cdl_varname,
                                 paramInfo[i].WFO_level_name,
                                 paramInfo[i].WFO_level,
                                 paramInfo[i].WFO_level_value);
            
        
            i++;
            }
                                 
        }
        
        
    *numOfElements = i;
        
    return SUCCESS;
    }                           

/******************************************************************/
int copyTemplateToNewCDFfile(char *templateFile, char *cdfFilename)
{
  char command[150];
  int status;     
    
    /* Make sure the template file exists */
    if(access(templateFile, F_OK) == 0)
        {  
        /* generate the system command string to do the copy */
        strcpy(command, "cp ");
        strcat(command, templateFile);
        strcat(command, " ");
        strcat(command, cdfFilename);
         
        /* Execute the copy. If there's a problem, log it + return false. */            
        if((status = system (command)) != 0)
            {
            return ERROR;
            }
        }
        
    /* template file for did not exist, so generate one. */
    else
        {

    /* Generate the system command string to do the NETCDF ncgen call. 
       The ncgen call creates a NETCDF template file loaded with FILL VALUES. */
        strcpy(command, "ncgen -o ");
        strcat(command, templateFile);
        strcat(command, " laps.cdl");
                       
        /* Execute the ncgen. If there's a problem, log it. */
        if((status = system(command)) != 0)
            {
            fprintf(stdout,"Failure on system command to copy template file.\n"); 
            fprintf(stdout,"Failure on command %s\n",command);
            return ERROR;
            }           
        /* Execute the copy command again, now that there's a template file. */
        else
            if(copyTemplateToNewCDFfile(templateFile, cdfFilename) != SUCCESS)
                return ERROR;
        }
        
    return SUCCESS;
}
/******************************************************************/
void filenameToUnixtime(time_t * refTime, time_t *validTime, char *filename)
{
        int hour_r, min_r, hour_v, min_v, j_day, yr, mo, day, sec, fn_len;
        char c_hour_r[3], c_min_r[3], c_hour_v[3], c_min_v[3]; 
        char c_j_day[4], c_yr[3], *p, c_mo[3], c_day[3];
        char timeString[30];

        fn_len = strlen(filename);
        p = filename + 8;
        if (fn_len == 13 && strncmp(p,"_",1) == 0) { /* wfo filename format */
          p = filename + 2;
          strncpy(c_yr,p,2);
          c_yr[2] = '\0';
          yr = atoi(c_yr);

          p = filename + 4;
          strncpy(c_mo,p,2);
          c_mo[2] = '\0';
          mo = atoi(c_mo);

          p = filename + 6;
          strncpy(c_day,p,2);
          c_day[2] = '\0';
          day = atoi(c_day);

          p = filename + 9;
          strncpy(c_hour_r,p,2);
          c_hour_r[2] = '\0';
          hour_r = atoi(c_hour_r);
          min_r = 0;

          p = filename + 11;
          strncpy(c_hour_v,p,2);
          c_hour_v[2] = '\0';
          hour_v = atoi(c_hour_v);
          min_v = 0;

        }
        else {
          strncpy(c_yr,filename,2);
          c_yr[2] = '\0';
          yr = atoi(c_yr);
 
          p = filename + 2;
          strncpy(c_j_day,p,3);
          c_j_day[3] = '\0';
          j_day = atoi(c_j_day);

          jdayToMoDay(j_day, yr, &mo, &day);

          p = filename + 5;
          strncpy(c_hour_r,p,2);
          c_hour_r[2] = '\0';
          hour_r = atoi(c_hour_r);
  
          if (fn_len == 9) {
            min_r = 0;

            p = filename + 7;
            strncpy(c_hour_v,p,2);
            c_hour_v[2] = '\0';
            hour_v = atoi(c_hour_v);
            min_v = 0;
          }
          else if (fn_len == 13) {
            p = filename + 7;
            strncpy(c_min_r,p,2);
            c_min_r[2] = '\0';
            min_r = atoi(c_min_r);

            p = filename + 9;
            strncpy(c_hour_v,p,2);
            c_hour_v[2] = '\0';
            hour_v = atoi(c_hour_v);

            p = filename + 11;
            strncpy(c_min_v,p,2);
            c_min_v[2] = '\0';
            min_v = atoi(c_min_v);
          }
        }

          sec = 0;
          *refTime = (time_t)dayInfo2unixtime(yr, mo, day, hour_r, min_r, sec);
          sec = 0;
          *validTime = *refTime + hour_v*3600 + min_v*60;

        return;
}

/*************************************************************************/
void jdayToMoDay(int jday, int yr, int *mo, int *day)
{
        int dayInMo[12];

        dayInMo[0] = 31;
        dayInMo[1] = 28;
        dayInMo[2] = 31;
        dayInMo[3] = 30;
        dayInMo[4] = 31;
        dayInMo[5] = 30;
        dayInMo[6] = 31;
        dayInMo[7] = 31;
        dayInMo[8] = 30;
        dayInMo[9] = 31;
        dayInMo[10] = 30;
        dayInMo[11] = 31;

        if (yr%4 == 0) dayInMo[1] = 29;

        *mo = 1;
        *day = jday;
        while (*day > dayInMo[*mo - 1]) {
          *day = *day - dayInMo[*mo - 1];
          *mo = *mo + 1;
        }
}
/*************************************************************************/
/* Y2K note:  This program will only work until 12/31/2069.  After that
              it will overlap with the 1/1/1970 start date of unixtime  */

long dayInfo2unixtime(int yr, int mo, int day, int hour, int min, int sec)
{

        int dayInMo[12], n_leap_1970_to_1999;
        long nsecmo[12];

        long nsecyr = 31536000, nsecda = 86400, nsechr = 3600, nsecmn = 60;
        long sum, nyr, nyrs, nleap, prevLeapYear, ibase, i;

        dayInMo[0] = 31;
        dayInMo[1] = 28;
        dayInMo[2] = 31;
        dayInMo[3] = 30;
        dayInMo[4] = 31;
        dayInMo[5] = 30;
        dayInMo[6] = 31;
        dayInMo[7] = 31;
        dayInMo[8] = 30;
        dayInMo[9] = 31;
        dayInMo[10] = 30;
        dayInMo[11] = 31;

        nsecmo[0] = 2678400;
        nsecmo[1] = 2419200;
        nsecmo[2] = 2678400;
        nsecmo[3] = 2592000;
        nsecmo[4] = 2678400;
        nsecmo[5] = 2592000;
        nsecmo[6] = 2678400;
        nsecmo[7] = 2678400;
        nsecmo[8] = 2592000;
        nsecmo[9] = 2678400;
        nsecmo[10] = 2592000;
        nsecmo[11] = 2678400;

        ibase = 70;
        prevLeapYear = 68;
        n_leap_1970_to_1999 = 7;

/* sum the number of years */
        nyr = yr;
        if (nyr > 1900) nyr = nyr - 1900;
        nyrs = nyr - ibase;

        if (nyr >= 70 && nyr <= 99) {
          nleap = ((nyr - prevLeapYear) / 4);
        }
        else if (nyr >= 0 && nyr < 70){
          nyrs = nyr + 30;
          prevLeapYear = 96;
          nleap = ((nyr + 100 - prevLeapYear) / 4) + n_leap_1970_to_1999; 
        }
        else { /* date is before 1/1/1970 or after 12/31/2069 */
          fprintf(stdout,"Date is before 1/1/1970 or after 12/31/2069.\n");
          fprintf(stdout,"Function filenameToUnixtime will not work.\n");
          return ERROR;
        }
        sum = nyrs * nsecyr + (nleap * nsecda);

/* sum the number of months */
        if ((mo < 1) || (mo > 12)) return ERROR;
        if (mo != 1) {
          for (i = 0; i < (mo - 1); i++) {
            sum = sum + nsecmo[i];
          }
        }

/* correct for Jan of Feb of a leap year */

        if ((nyr % 4) == 0) {
          if (mo <= 2) sum = sum - nsecda;
        }
/* sum the number of days */
        if ((day < 1) || (day > dayInMo[mo - 1])) return ERROR;
        sum = sum + ((day - 1) * nsecda);

/* sum the number of hours */
        if ((hour < 0) || (hour > 23)) return ERROR;
        sum = sum + (hour * nsechr);

/* sum the number of mins */
        if ((min < 0) || (min > 59)) return ERROR;
        sum = sum + (min * nsecmn);

/* sum the number of secs */
        if ((sec < 0) || (sec > 59)) return ERROR;
        sum = sum + sec;

        return sum;
}
/*************************************************************************/
int get_n_valtimes(long *n_valtimes)
{
        int cdfId, mode = NC_NOWRITE, status, dimId;    
        char fname[128];

        strcpy(fname,getenv("WFO_FCSTPRD"));
        strcat(fname,"/template");
        
        cdfId = ncopen ((const char *)fname, mode);     
        if(cdfId == NC_SYSERR) {
          fprintf(stdout,"Error opening template file %s\n",fname);
          return ERROR;
        }
   
/* get value of n_valtimes, used to store inventory and tells how many files to check for */
        dimId = ncdimid(cdfId, (const char *)"n_valtimes");
        ncdiminq(cdfId, dimId, (char *) 0, (long *)n_valtimes);
        ncclose(cdfId);

        if (*n_valtimes >= 1)
          return SUCCESS;
        else {
          fprintf(stdout, "n_valtimes dimension in template file not >= 1. \n");
          return ERROR;
        }
}
/*************************************************************************/
