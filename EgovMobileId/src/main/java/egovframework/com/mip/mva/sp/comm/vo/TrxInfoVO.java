package egovframework.com.mip.mva.sp.comm.vo;

import java.io.Serializable;

/**
 * @Project 모바일 운전면허증 서비스 구축 사업
 * @PackageName mip.mva.sp.comm.vo
 * @FileName TrxInfoVO.java
 * @Author Min Gi Ju
 * @Date 2022. 6. 3.
 * @Description 거래정보 VO
 * 
 * <pre>
 * ==================================================
 * DATE            AUTHOR           NOTE
 * ==================================================
 * 2024. 5. 28.    민기주           최초생성
 * 2025.02. 13.    박성완           표준프레임워크 v4.3 - toString 메서드 추가
 * </pre>
 */
public class TrxInfoVO implements Serializable {

	private static final long serialVersionUID = 1L;

	/** 거래코드 */
	private String trxcode;
	/** 서비스코드 */
	private String svcCode;
	/** 모드 */
	private String mode;
	/** nonce(presentType=1) */
	private String nonce;
	/** zkpNonce(presentType=2) */
	private String zkpNonce;
	/** VP 검증 결과 여부 */
	private String vpVerifyResult;
	/** VP */
	private String vp;
	/** 거래상태코드(0001: 서비스요청, 0002: profile요청, 0003: VP 검증요청, 0004: VP 검증완료) */
	private String trxStsCode;
	/** profile 송신일시(M310) */
	private String profileSendDt;
	/** 이미지 송신일시(M320) */
	private String imgSendDt;
	/** VP 수신일시(M400) */
	private String vpReceptDt;
	/** 오류 내용 */
	private String errorCn;
	/** 등록일시 */
	private String regDt;
	/** 수정일시 */
	private String udtDt;

	public String getSvcCode() {
		return svcCode;
	}

	public String getTrxcode() {
		return trxcode;
	}

	public void setTrxcode(String trxcode) {
		this.trxcode = trxcode;
	}

	public void setSvcCode(String svcCode) {
		this.svcCode = svcCode;
	}

	public String getMode() {
		return mode;
	}

	public void setMode(String mode) {
		this.mode = mode;
	}

	public String getNonce() {
		return nonce;
	}

	public void setNonce(String nonce) {
		this.nonce = nonce;
	}

	public String getZkpNonce() {
		return zkpNonce;
	}

	public void setZkpNonce(String zkpNonce) {
		this.zkpNonce = zkpNonce;
	}

	public String getVpVerifyResult() {
		return vpVerifyResult;
	}

	public void setVpVerifyResult(String vpVerifyResult) {
		this.vpVerifyResult = vpVerifyResult;
	}

	public String getVp() {
		return vp;
	}

	public void setVp(String vp) {
		this.vp = vp;
	}

	public String getTrxStsCode() {
		return trxStsCode;
	}

	public void setTrxStsCode(String trxStsCode) {
		this.trxStsCode = trxStsCode;
	}

	public String getProfileSendDt() {
		return profileSendDt;
	}

	public void setProfileSendDt(String profileSendDt) {
		this.profileSendDt = profileSendDt;
	}

	public String getImgSendDt() {
		return imgSendDt;
	}

	public void setImgSendDt(String imgSendDt) {
		this.imgSendDt = imgSendDt;
	}

	public String getVpReceptDt() {
		return vpReceptDt;
	}

	public void setVpReceptDt(String vpReceptDt) {
		this.vpReceptDt = vpReceptDt;
	}

	public String getErrorCn() {
		return errorCn;
	}

	public void setErrorCn(String errorCn) {
		this.errorCn = errorCn;
	}

	public String getRegDt() {
		return regDt;
	}

	public void setRegDt(String regDt) {
		this.regDt = regDt;
	}

	public String getUdtDt() {
		return udtDt;
	}

	public void setUdtDt(String udtDt) {
		this.udtDt = udtDt;
	}
	
	// toString 메서드 추가(2025.02.13 박성완)
	@Override
	public String toString() {
	    return "TrxInfo{ " +
	            "trxcode = " + trxcode + " | " +
	            "svcCode = " + svcCode + " | " +
	            "mode = " + mode + " | " +
	            "nonce = " + nonce + " | " +
	            "zkpNonce = " + zkpNonce + " | " +
	            "vpVerifyResult = " + vpVerifyResult + " | " +
	            "vp = " + vp + " | " +
	            "trxStsCode = " + trxStsCode + " | " +
	            "profileSendDt = " + profileSendDt + " | " +
	            "imgSendDt = " + imgSendDt + " | " +
	            "vpReceptDt = " + vpReceptDt + " | " +
	            "errorCn = " + errorCn + " | " +
	            "regDt = " + regDt + " | " +
	            "udtDt = " + udtDt +
	            "}";
	}


}
