package egovframework.com.uss.olp.qrm.repository;

import egovframework.com.uss.olp.qrm.entity.QustnrRespondInfo;
import egovframework.com.uss.olp.qrm.entity.QustnrRespondInfoId;
import egovframework.com.uss.olp.qrm.service.QustnrRespondInfoDTO;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository("qrmEgovQustnrRespondInfoRepository")
public interface EgovQustnrRespondInfoRepository extends JpaRepository<QustnrRespondInfo, QustnrRespondInfoId> {

    @Query("SELECT new egovframework.com.uss.olp.qrm.service.QustnrRespondInfoDTO( " +
            "a.qustnrRespondInfoId.qustnrTmplatId, " +
            "a.qustnrRespondInfoId.qestnrId, " +
            "c.qustnrSj, " +
            "a.qustnrRespondInfoId.qustnrRespondId, " +
            "a.sexdstnCode, " +
            "d.codeNm, " +
            "a.occpTyCode, " +
            "e.codeNm, " +
            "a.respondNm, " +
            "COALESCE(FUNCTION('DATE_FORMAT', a.frstRegistPnttm, '%Y-%m-%d'), ''), " +
            "a.frstRegisterId, " +
            "COALESCE(FUNCTION('DATE_FORMAT', a.lastUpdtPnttm, '%Y-%m-%d'), ''), " +
            "a.lastUpdusrId, " +
            "b.userNm " +
            ") " +
            "FROM qrmQustnrRespondInfo a " +
            "LEFT OUTER JOIN qrmUserMaster b " +
            "ON a.frstRegisterId = b.esntlId " +
            "LEFT OUTER JOIN qrmQestnrInfo c " +
            "ON a.qustnrRespondInfoId.qestnrId = c.qestnrInfoId.qestnrId " +
            "LEFT OUTER JOIN qrmCmmnDetailCode d " +
            "ON a.sexdstnCode = d.cmmnDetailCodeId.code " +
            "AND d.cmmnDetailCodeId.codeId = 'COM014' " +
            "LEFT OUTER JOIN qrmCmmnDetailCode e " +
            "ON a.occpTyCode = e.cmmnDetailCodeId.code " +
            "AND e.cmmnDetailCodeId.codeId = 'COM034' " +
            "WHERE ( " +
            "(:searchCondition = '1' AND (:searchKeyword IS NULL OR a.respondNm LIKE %:searchKeyword%)) OR " +
            "(:searchCondition = '2' AND (:searchKeyword IS NULL OR b.userNm LIKE %:searchKeyword%)) " +
            ") " +
            "ORDER BY a.frstRegistPnttm DESC "
    )
    Page<QustnrRespondInfoDTO> qustnrRespondInfoList(
            @Param("searchCondition") String searchCondition,
            @Param("searchKeyword") String searchKeyword,
            Pageable pageable);

    @Query("SELECT new egovframework.com.uss.olp.qrm.service.QustnrRespondInfoDTO( " +
            "a.qustnrRespondInfoId.qustnrTmplatId, " +
            "a.qustnrRespondInfoId.qestnrId, " +
            "c.qustnrSj, " +
            "a.qustnrRespondInfoId.qustnrRespondId, " +
            "a.sexdstnCode, " +
            "d.codeNm, " +
            "a.occpTyCode, " +
            "e.codeNm, " +
            "a.respondNm, " +
            "COALESCE(FUNCTION('DATE_FORMAT', a.frstRegistPnttm, '%Y-%m-%d'), ''), " +
            "a.frstRegisterId, " +
            "COALESCE(FUNCTION('DATE_FORMAT', a.lastUpdtPnttm, '%Y-%m-%d'), ''), " +
            "a.lastUpdusrId, " +
            "b.userNm " +
            ") " +
            "FROM qrmQustnrRespondInfo a " +
            "LEFT OUTER JOIN qrmUserMaster b " +
            "ON a.frstRegisterId = b.esntlId " +
            "LEFT OUTER JOIN qrmQestnrInfo c " +
            "ON a.qustnrRespondInfoId.qestnrId = c.qestnrInfoId.qestnrId " +
            "LEFT OUTER JOIN qrmCmmnDetailCode d " +
            "ON a.sexdstnCode = d.cmmnDetailCodeId.code " +
            "AND d.cmmnDetailCodeId.codeId = 'COM014' " +
            "LEFT OUTER JOIN qrmCmmnDetailCode e " +
            "ON a.occpTyCode = e.cmmnDetailCodeId.code " +
            "AND e.cmmnDetailCodeId.codeId = 'COM034' " +
            "WHERE a.qustnrRespondInfoId.qustnrRespondId = :qustnrRespondId "
    )
    QustnrRespondInfoDTO qustnrRespondInfoDetail(String qustnrRespondId);

}
