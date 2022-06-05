package com.heima.item.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.benmanes.caffeine.cache.Cache;
import com.heima.item.pojo.Item;
import com.heima.item.pojo.ItemStock;
import com.heima.item.service.IItemService;
import com.heima.item.service.IItemStockService;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class RedisHandler implements InitializingBean {
    @Autowired
    private StringRedisTemplate stringRedisTemplate;
    @Autowired
    private IItemService itemService;
    @Autowired
    private IItemStockService itemStockService;
    @Autowired
    private Cache<Long, Item> itemCache;

    //spring默认json处理工具
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    @Override
    public void afterPropertiesSet() throws Exception {
        //初始化缓存
        final List<Item> itemList = itemService.list();
        for (Item item : itemList) {
            final String json = OBJECT_MAPPER.writeValueAsString(item);
            stringRedisTemplate.opsForValue().set("item:id:" + item.getId(), json);
        }

        final List<ItemStock> stockList = itemStockService.list();
        for (ItemStock stock : stockList) {
            final String json = OBJECT_MAPPER.writeValueAsString(stock);
            stringRedisTemplate.opsForValue().set("stock:id:" + stock.getId(), json);
        }
    }

    public void addUpdateItemCache(Item item) {
        itemCache.put(item.getId(), item);
        final String json;
        try {
            json = OBJECT_MAPPER.writeValueAsString(item);
            stringRedisTemplate.opsForValue().set(item.getId().toString(), json);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

    }

    public void delItemCache(Item item) {
        itemCache.invalidate(item.getId());
        stringRedisTemplate.delete(item.getId().toString());

    }

}
