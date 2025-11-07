package com.fleamap.flea_map_app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = {DataSourceAutoConfiguration.class })
public class FleaMapAppApplication {

	public static void main(String[] args) {
		SpringApplication.run(FleaMapAppApplication.class, args);
	}

}
