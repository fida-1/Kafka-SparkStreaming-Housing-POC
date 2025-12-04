package com.example;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.BufferedReader;
import java.io.FileReader;
import java.nio.file.Paths;
import java.util.Properties;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import java.util.Arrays;

public class KafkaProducerApp {

    private static final String TOPIC = "housing-data";
    private static final int BATCH_SIZE = 100; // Microbatch size

    public static void main(String[] args) {
        System.out.println("Kafka Producer starting...");
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());

        KafkaProducer<String, String> producer = new KafkaProducer<>(props);
        ObjectMapper mapper = new ObjectMapper();
        int totalRecords = 0;

        try (BufferedReader br = new BufferedReader(new FileReader("../data/housing.csv"))) {
            System.out.println("Reading CSV file...");
            String line;
            boolean header = true;
            List<Map<String, String>> batch = new ArrayList<>();
            int lineCount = 0;

            while ((line = br.readLine()) != null) {
                lineCount++;
                if (header) {
                    header = false;
                    System.out.println("Skipping header");
                    continue;
                }

                String[] values = line.trim().replaceAll("\\s+", " ").split(" ");
                if (values.length >= 14) {
                    // Take the first 14 columns, ensure they're valid
                    Map<String, String> record = new HashMap<>();
                    try {
                        record.put("crim", values[0]);
                        record.put("zn", values[1]);
                        record.put("indus", values[2]);
                        record.put("chas", values[3]);
                        record.put("nox", values[4]);
                        record.put("rm", values[5]);
                        record.put("age", values[6]);
                        record.put("dis", values[7]);
                        record.put("rad", values[8]);
                        record.put("tax", values[9]);
                        record.put("ptratio", values[10]);
                        record.put("b", values[11]);
                        record.put("lstat", values[12]);
                        record.put("medv", values[13]);
                        batch.add(record);
                    } catch (Exception e) {
                        // Skip lines that can't be parsed
                    }
                    totalRecords++;

                    if (batch.size() == BATCH_SIZE) {
                        sendBatch(producer, mapper, batch);
                        batch.clear();
                    }
                } else {
                    System.err.println("Line " + lineCount + " has " + values.length + " columns after filter (skipped): " + line.substring(0, Math.min(line.length(), 100)));
                }
            }

            // Send remaining batch
            if (!batch.isEmpty()) {
                sendBatch(producer, mapper, batch);
            }
            System.out.println("Total records processed: " + totalRecords);
        } catch (Exception e) {
            System.err.println("Fatal error: ");
            e.printStackTrace();
        } finally {
            producer.close();
            System.out.println("Producer closed. Exiting.");
        }
    }

    private static void sendBatch(KafkaProducer<String, String> producer, ObjectMapper mapper, List<Map<String, String>> batch) throws Exception {
        String json = mapper.writeValueAsString(batch);
        ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC, json);
        producer.send(record);
        System.out.println("Sent batch of " + batch.size() + " records to Kafka");
    }
}
