package se.callista.cadec;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class QuoteController {

	Map<String, List<String>> quotes;
	Random random = new Random();
	
	public QuoteController() {
		quotes = new HashMap<>();
		quotes.put("en", Arrays.<String>asList("To be or not to be", "You, too, Brutus?", "Champagne should be cold, dry and free"));
		quotes.put("sv", Arrays.<String>asList("Att vara eller inte vara", "Även du, min Brutus?", "Champagne skall vara kall, torr och gratis"));
	}
	
    @RequestMapping("/quote")
    public Quote quote(@RequestParam(value="language", defaultValue="en") String language) {
		List<String> list = quotes.get(language);
		String s = list.get(random.nextInt(list.size()));
		Quote quote = new Quote();
		quote.setQuote(s);
		quote.setLanguage(language);
		return quote;
    }
}