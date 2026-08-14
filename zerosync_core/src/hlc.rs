use std::cmp::Ordering;
use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Hlc {
    pub millis: i64,
    pub counter: u32,
    pub node_id: String,
}

impl Hlc {
    pub fn new(millis: i64, counter: u32, node_id: String) -> Self {
        Self { millis, counter, node_id }
    }

    pub fn now(node_id: String) -> Self {
        Self {
            millis: Utc::now().timestamp_millis(),
            counter: 0,
            node_id,
        }
    }

    pub fn increment(&self, wall_time_millis: i64) -> Self {
        if wall_time_millis > self.millis {
            Self::new(wall_time_millis, 0, self.node_id.clone())
        } else {
            Self::new(self.millis, self.counter + 1, self.node_id.clone())
        }
    }

    pub fn to_string_fmt(&self) -> String {
        format!("{}:{:.4}:{}", self.millis, self.counter, self.node_id)
    }
}

impl Ord for Hlc {
    fn cmp(&self, other: &Self) -> Ordering {
        match self.millis.cmp(&other.millis) {
            Ordering::Equal => match self.counter.cmp(&other.counter) {
                Ordering::Equal => self.node_id.cmp(&other.node_id),
                other_cmp => other_cmp,
            },
            other_cmp => other_cmp,
        }
    }
}

impl PartialOrd for Hlc {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
