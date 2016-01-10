package se.callista.cadec;

import java.util.Arrays;
import java.util.List;
import java.util.Random;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class QuoteController {

	List<String> quotes;
	Random random = new Random();
	
	public QuoteController() {
		quotes = Arrays.<String>asList("To be or not to be", "You, too, Brutus?", "Champagne should be cold, dry and free");
	}
	
    @RequestMapping("/quote")
    public Quote quote(@RequestParam(value="language", defaultValue="en") String language) {
		String s = quotes.get(random.nextInt(quotes.size()));
		Quote quote = new Quote();
		quote.setQuote(s);
		quote.setLanguage(language);
		return quote;
    }
}