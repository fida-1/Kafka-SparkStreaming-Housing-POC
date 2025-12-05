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
        // Configuration ObjectMapper sans null bytes
        ObjectMapper mapper = new ObjectMapper();
        mapper.getFactory().configure(com.fasterxml.jackson.core.JsonGenerator.Feature.WRITE_BIGDECIMAL_AS_PLAIN, true);

        int totalRecords = 0;

        try (BufferedReader br = new BufferedReader(new FileReader("../data/housing.csv"))) {
            System.out.println("Reading CSV file...");
            String line;
            boolean header = true;
            List<List<String>> batch = new ArrayList<>();
            java.util.regex.Pattern pattern = java.util.regex.Pattern.compile("\\s+");
            int lineCount = 0;

            while ((line = br.readLine()) != null) {
                lineCount++;
                if (header) {
                    header = false;
                    System.out.println("Skipping header");
                    continue;
                }

                // Parser correctement le CSV Boston Housing (séparé par espaces multiples)
                String[] values = pattern.split(line.trim());
                if (values.length >= 14) {
                    List<String> record = new ArrayList<>();
                    try {
                        // Prendre exactement les 14 colonnes
                        for (int i = 0; i < 14; i++) {
                            String cleanValue = values[i].trim().replaceAll("\\u0000", "").replaceAll("\\r?\\n", "");
                            record.add(cleanValue);
                        }
                        batch.add(record);
                        totalRecords++;
                    } catch (Exception e) {
                        System.err.println("Error parsing line " + lineCount + " after filter: " + e.getMessage());
                    }

                    if (batch.size() == BATCH_SIZE) {
                        sendBatch(producer, mapper, batch);
                        batch.clear();
                    }
                } else {
                    System.err.println("Line " + lineCount + " has " + values.length + " columns after filter (skipped): ");
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

    private static void sendBatch(KafkaProducer<String, String> producer, ObjectMapper mapper, List<List<String>> batch) throws Exception {
        // Créer un JSON propre sans caractères null
        StringBuilder jsonBuilder = new StringBuilder();
        jsonBuilder.append("[");

        for (int i = 0; i < batch.size(); i++) {
            List<String> record = batch.get(i);
            if (i > 0) jsonBuilder.append(",");

            // Construire JSON manuellement pour éviter les caractères null
            jsonBuilder.append("{");
            jsonBuilder.append("\"crim\":\"").append(record.get(0)).append("\",");
            jsonBuilder.append("\"zn\":\"").append(record.get(1)).append("\",");
            jsonBuilder.append("\"indus\":\"").append(record.get(2)).append("\",");
            jsonBuilder.append("\"chas\":\"").append(record.get(3)).append("\",");
            jsonBuilder.append("\"nox\":\"").append(record.get(4)).append("\",");
            jsonBuilder.append("\"rm\":\"").append(record.get(5)).append("\",");
            jsonBuilder.append("\"age\":\"").append(record.get(6)).append("\",");
            jsonBuilder.append("\"dis\":\"").append(record.get(7)).append("\",");
            jsonBuilder.append("\"rad\":\"").append(record.get(8)).append("\",");
            jsonBuilder.append("\"tax\":\"").append(record.get(9)).append("\",");
            jsonBuilder.append("\"ptratio\":\"").append(record.get(10)).append("\",");
            jsonBuilder.append("\"b\":\"").append(record.get(11)).append("\",");
            jsonBuilder.append("\"lstat\":\"").append(record.get(12)).append("\",");
            jsonBuilder.append("\"medv\":\"").append(record.get(13)).append("\"");
            jsonBuilder.append("}");
        }

        jsonBuilder.append("]");

        String json = jsonBuilder.toString();
        ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC, json);
        producer.send(record);
        System.out.println("Sent batch of " + batch.size() + " records to Kafka");
    }
}
