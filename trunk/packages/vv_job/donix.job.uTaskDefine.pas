unit donix.job.uTaskDefine;

interface

type
  TTaskRunStatus = (trsUnknown, trsRunning, trsStop, trsSuspend);

  TTaskConfigRec = record
    FileName: string;
    TaskName: string;
    Interactive: integer;
    Description: string;
    Version: string;
    Auth: string;

    StepsStr: string;

    //������������jobmgr����ʱ����
    RunBasePath: string;
    DBsConfigFile: string;
  end;


implementation

end.
