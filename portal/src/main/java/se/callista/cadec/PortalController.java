package se.callista.cadec;

import java.util.Locale;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.client.RestTemplate;

@Controller
public class PortalController {

	@Value("${quote.server}")
	private String quoteServer;
	
	@Value("${quote.port}")
	private String quotePort;
	
    RestTemplate restTemplate = new RestTemplate();

    @RequestMapping("/home")
    public String home(Model model, Locale locale) {
    	String language = locale.getLanguage();
        Quote quote = restTemplate.getForObject("http://"+quoteServer+":"+quotePort+"/quote?language="+language, Quote.class);
    	model.addAttribute("quote", quote.getQuote());
        return "home";
    }
}