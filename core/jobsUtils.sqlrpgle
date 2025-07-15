**FREE
ctl-opt dftactgrp(*no) actgrp(*new) option(*srcstmt: *nodebugio)
         main(relanceServeurs) bnddir('SERVICE');

/copy qrpglesrc,utiproc
/copy Qrpglesrc,inh32766
/copy qrpglesrc,psds

Dcl-pr sleep int(10) extproc('sleep');
  seconds uns(10) value;
end-pr;

Dcl-proc relanceServeurs;
  dcl-pi relanceServeurs extpgm('REPSVRISTA');

  end-pi;

  Dcl-s statutCommande varchar(50) inz;
  Dcl-s delai uns(10); // Délai en secondes entre les relances
  Dcl-s programme like(r_procedure_name);
  programme = procedure;

  dow %time() < %time('18.00.00':*Iso);
    Exec sql close serveurssurveilles;

    Exec sql
      declare serveurssurveilles cursor for
        SELECT CASE
             WHEN QSYS2.QCMDEXC('QSH CMD(''/QOpenSys/pkgs/bin/' concat
                               TRIM(a.CSCOM1) concat ''')') = 1 THEN 'Service ' concat trim(a.Cscom1) concat ' Relancé'
             ELSE 'Problème Service ' concat trim(a.Cscom1) concat ' non relancé : voir joblog'
       END AS "Statut Cmd"
       FROM Bntabp A
             LEFT JOIN (
             SELECT Job_Name_Short
                   FROM TABLE (
                   Qsys2.Active_Job_Info(Detailed_Info => 'ALL')
                   ) X
             )
             ON Job_Name_Short = A.Csccod
       WHERE A.Cscprm = 'RSSVR' and Job_Name_Short is null;

    Exec sql open serveurssurveilles;
    Sqlerreur(Sqlca);

    dou sqlcode = 100;
      Exec sql fetch serveurssurveilles into :statutCommande;
      Sqlerreur(Sqlca);
      dsply statutCommande;
    enddo;
    delai=delai_job(programme);
    sleep(delai);
  enddo;

  Exec sql close serveurssurveilles;

  Return;
end-proc;