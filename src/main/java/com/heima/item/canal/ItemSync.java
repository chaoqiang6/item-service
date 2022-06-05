package com.heima.item.canal;

import com.heima.item.config.RedisHandler;
import com.heima.item.pojo.Item;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import top.javatool.canal.client.annotation.CanalTable;
import top.javatool.canal.client.handler.EntryHandler;
@Component
@CanalTable("tb_item")
public class ItemSync implements EntryHandler<Item> {

    @Autowired
    private RedisHandler redisHandler;
    @Override
    public void insert(Item item) {
        redisHandler.addUpdateItemCache(item);
    }

    @Override
    public void update(Item before, Item after) {
        redisHandler.addUpdateItemCache(after);
    }

    @Override
    public void delete(Item item) {
        redisHandler.delItemCache(item);
    }
}
