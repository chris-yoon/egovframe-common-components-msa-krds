package egovframework.com.cop.bls.service.impl;

import egovframework.com.cop.bls.entity.BbsMaster;
import egovframework.com.cop.bls.repository.EgovBbsMasterOptionRepository;
import egovframework.com.cop.bls.repository.EgovBbsMasterRepository;
import egovframework.com.cop.bls.service.BbsMasterDTO;
import egovframework.com.cop.bls.service.BbsMasterOptnVO;
import egovframework.com.cop.bls.service.BbsMasterVO;
import egovframework.com.cop.bls.service.EgovBbsMasterService;
import egovframework.com.cop.bls.util.EgovBlogUtility;
import org.apache.commons.lang3.RandomStringUtils;
import org.egovframe.rte.fdl.cmmn.EgovAbstractServiceImpl;
import org.egovframe.rte.fdl.cmmn.exception.FdlException;
import org.egovframe.rte.fdl.idgnr.EgovIdGnrService;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Map;

@Service("blsEgovBbsMasterService")
public class EgovBbsMasterServiceImpl extends EgovAbstractServiceImpl implements EgovBbsMasterService {

    private final EgovBbsMasterRepository repository;
    private final EgovBbsMasterOptionRepository optionRepository;
    private final EgovIdGnrService idgenService;

    public EgovBbsMasterServiceImpl(
            EgovBbsMasterRepository repository,
            EgovBbsMasterOptionRepository optionRepository,
            @Qualifier("egovBBSMstrIdGnrService") EgovIdGnrService idgenService
    ) {
        this.repository = repository;
        this.optionRepository = optionRepository;
        this.idgenService = idgenService;
    }

    @Override
    public Page<BbsMasterDTO> list(BbsMasterVO bbsMasterVO) {
        Pageable pageable = PageRequest.of(bbsMasterVO.getFirstIndex(), bbsMasterVO.getRecordCountPerPage());
        String searchCondition = bbsMasterVO.getSearchCondition();
        String searchKeyword = bbsMasterVO.getSearchKeyword();
        String blogId = bbsMasterVO.getBlogId();
        return repository.bbsMasterList(searchCondition, searchKeyword, blogId, pageable);
    }

    @Override
    public BbsMasterDTO detail(BbsMasterVO bbsMasterVO) {
        return repository.bbsMasterDetail(bbsMasterVO.getBbsId(), bbsMasterVO.getBlogId());
    }

    @Transactional
    @Override
    public BbsMasterVO insert(BbsMasterVO bbsMasterVO, Map<String, String> userInfo) throws FdlException {
        String bbsId = idgenService.getNextStringId()+ RandomStringUtils.randomAlphabetic(10);

        BbsMasterOptnVO bbsMasterOptnVO = getBbsMasterOptnVO(bbsMasterVO, bbsId, userInfo.get("uniqId"));
        if (!"1".equals(bbsMasterVO.getBbsOption())) {
            optionRepository.save(EgovBlogUtility.bbsMasterOptnVOEntity(bbsMasterOptnVO));
        }

        bbsMasterVO.setBbsId(bbsId);
        bbsMasterVO.setFrstRegistPnttm(LocalDateTime.now());
        bbsMasterVO.setFrstRegisterId(userInfo.get("uniqId"));
        bbsMasterVO.setLastUpdtPnttm(LocalDateTime.now());
        bbsMasterVO.setLastUpdusrId(userInfo.get("uniqId"));
        BbsMaster bbsMaster = repository.save(EgovBlogUtility.bbsMasterVOTOEntity(bbsMasterVO));

        return EgovBlogUtility.bbsMasterEntityTOVO(bbsMaster);
    }

    @Transactional
    @Override
    public BbsMasterVO update(BbsMasterVO bbsMasterVO, Map<String, String> userInfo) {
        if (!"1".equals(bbsMasterVO.getBbsOption())) {
            BbsMasterOptnVO bbsMasterOptnVO = getBbsMasterOptnVO(bbsMasterVO, bbsMasterVO.getBbsId(), userInfo.get("uniqId"));
            optionRepository.findById(bbsMasterOptnVO.getBbsId())
                    .map(result -> {
                        result.setAnswerAt(bbsMasterOptnVO.getAnswerAt());
                        result.setStsfdgAt(bbsMasterOptnVO.getStsfdgAt());
                        result.setLastUpdtPnttm(LocalDateTime.now());
                        result.setLastUpdusrId(userInfo.get("uniqId"));
                        return optionRepository.save(result);
                    })
                    .orElseGet(() -> optionRepository.save(EgovBlogUtility.bbsMasterOptnVOEntity(bbsMasterOptnVO)));
        }

        return repository.findById(bbsMasterVO.getBbsId())
                .map(result -> {
                    result.setBbsNm(bbsMasterVO.getBbsNm());
                    result.setBbsIntrcn(bbsMasterVO.getBbsIntrcn());
                    result.setBbsTyCode(bbsMasterVO.getBbsTyCode());
                    result.setReplyPosblAt(bbsMasterVO.getReplyPosblAt());
                    result.setFileAtchPosblAt(bbsMasterVO.getFileAtchPosblAt());
                    result.setAtchPosblFileNumber(bbsMasterVO.getAtchPosblFileNumber());
                    result.setUseAt(bbsMasterVO.getUseAt());
                    result.setLastUpdtPnttm(LocalDateTime.now());
                    result.setLastUpdusrId(userInfo.get("uniqId"));
                    return repository.save(result);
                })
                .map(EgovBlogUtility::bbsMasterEntityTOVO).orElse(null);
    }

    private BbsMasterOptnVO getBbsMasterOptnVO(BbsMasterVO bbsMasterVO, String bbsId, String uniqId) {
        BbsMasterOptnVO bbsMasterOptnVO = new BbsMasterOptnVO();
        bbsMasterOptnVO.setBbsId(bbsId);
        if ("2".equals(bbsMasterVO.getBbsOption())) {
            bbsMasterOptnVO.setAnswerAt("Y");
            bbsMasterOptnVO.setStsfdgAt("N");
        } else if ("3".equals(bbsMasterVO.getBbsOption())) {
            bbsMasterOptnVO.setAnswerAt("N");
            bbsMasterOptnVO.setStsfdgAt("Y");
        } else {
            bbsMasterOptnVO.setAnswerAt("N");
            bbsMasterOptnVO.setStsfdgAt("N");
        }
        bbsMasterOptnVO.setFrstRegistPnttm(LocalDateTime.now());
        bbsMasterOptnVO.setFrstRegisterId(uniqId);
        bbsMasterOptnVO.setLastUpdtPnttm(LocalDateTime.now());
        bbsMasterOptnVO.setLastUpdusrId(uniqId);
        return bbsMasterOptnVO;
    }

}
