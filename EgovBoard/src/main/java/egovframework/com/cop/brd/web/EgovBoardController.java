package egovframework.com.cop.brd.web;

import egovframework.com.cop.brd.service.BbsVO;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.core.env.Environment;
import org.springframework.beans.factory.annotation.Autowired;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

@Controller("brdEgovBoardController")
@RequestMapping("/cop/brd")
public class EgovBoardController {
    private final Logger logger = LoggerFactory.getLogger(EgovBoardController.class);
    
    @Autowired
    private Environment env;

    @GetMapping(value = "/index")
    public String index(BbsVO bbsVO, Model model) {
        return boardListView(bbsVO, model);
    }

    @RequestMapping(value = "/boardListView", method = {RequestMethod.GET, RequestMethod.POST})
    public String boardListView(BbsVO bbsVO, Model model) {
        model.addAttribute("bbsVO", bbsVO);
        return "cop/brd/boardList";
    }

    @PostMapping(value = "/boardDetailView")
    public String boardDetailView(BbsVO bbsVO, Model model) {
        model.addAttribute("bbsVO", bbsVO);
        return "cop/brd/boardDetail";
    }

    @PostMapping(value = "/boardInsertView")
    public String boardInsertView(BbsVO bbsVO, Model model) {
        model.addAttribute("bbsVO", bbsVO);
        System.out.println("답글 - Controller > " + bbsVO.getAnswerAt());
        return "cop/brd/boardInsert";
    }

    @PostMapping(value = "/boardUpdateView")
    public String boardUpdateView(BbsVO bbsVO, Model model) {
        model.addAttribute("bbsVO", bbsVO);
        return "cop/brd/boardUpdate";
    }

    @GetMapping("/actuator/health-info")
    public ResponseEntity<String> status() {
        try {
            String response = String.format("GET EgovBoard Service on" +
                    "\n local.server.port: %s" +
                    "\n egov.message: %s",
                    env.getProperty("local.server.port"),
                    env.getProperty("egov.message")
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error in health-info endpoint: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error checking health info: " + e.getMessage());
        }
    }

    @PostMapping("/actuator/health-info")
    public ResponseEntity<String> poststatus() {
        try {
            String response = String.format("POST EgovBoard Service on" +
                    "\n local.server.port: %s" +
                    "\n egov.message: %s",
                    env.getProperty("local.server.port"),
                    env.getProperty("egov.message")
            );
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            logger.error("Error in health-info endpoint: ", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Error checking health info: " + e.getMessage());
        }
    }
}
